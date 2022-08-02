#!/usr/bin/bash
#
# backdrop-firstboot
#
# Author: Daniel J. R. May
#
# This script configures the backdrop installation for development by
# creating a database and automatically installing backdrop (if
# configured to do so by environment variables). This script should be
# called only once by the backdrop-firstboot service. It creates a
# lock file to prevent repeated executions.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-rpm


declare -r identifier='backdrop-firstboot'
declare -r lock_path='/var/lock/backdrop-firstboot.lock'
declare -r secrets_path='/run/secrets/backdrop-firstboot'
declare -r settings_path='/etc/backdrop/settings.php'
declare -r httpd_conf_path='/etc/httpd/conf.d/backdrop.conf'

# Check that this script has not already run, by checking for a lock
# file.
if [ -f "$lock_path" ]; then
	systemd-cat --identifier=$identifier --priority=warning \
		echo "Lock file $lock_path already exists, exiting."
	exit 1
else
	(
		touch $lock_path &&
			systemd-cat \
				--identifier=$identifier \
				echo "Created $lock_path to prevent the re-running of this script."
	) || (
		systemd-cat \
			--identifier=$identifier \
			--priority=error \
			echo "Failed to create $lock_path so exiting." &&
			exit 2
	)
fi


# Source the secrets file if it exists, if it doesn't then we report a
# warning and will fall back to some default values.
# shellcheck source=backdrop-firstboot.secrets
if source $secrets_path; then
	systemd-cat --identifier=$identifier \
		echo "Successfully sourced $secrets_path secrets file."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=warning \
		echo "Failed to source secrets file $secrets_path so will fall back to default values."
fi


# Set the values of all variables which have not been set by the
# secrets file or the environment.
: "${MAPPED_PORT:=48080}"
: "${BACKDROP_DATABASE_NAME:=backdrop}"
: "${BACKDROP_DATABASE_USER:=backdrop_db_user}"
: "${BACKDROP_DATABASE_PASSWORD:=backdrop_db_pwd}"
: "${BACKDROP_DATABASE_HOST:=localhost}"
: "${BACKDROP_DATABASE_PREFIX:=}"


# Create the Apache HTTPD server configuration file.
# Settings file configuration
cat > $httpd_conf_path <<EOF
# Apache configuration for the backdrop-VERSION-rpm-test container
# image.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-rpm

DocumentRoot "/usr/share/backdrop"

<Directory "/usr/share/backdrop">
    Require all granted
    AllowOverride All
</Directory>

# Listen on the container hosts mapped port (as well as port 80) so
# that backdrop is able to access itself via HTTP. This is required
# for things like the Testing module to work.
Listen $MAPPED_PORT
EOF

if [ -f $httpd_conf_path ]; then
	systemd-cat \
		--identifier=$identifier \
		echo "Created $httpd_conf_path with additional port $MAPPED_PORT."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to create $httpd_conf_path so exiting."
	exit 3
fi


# Create and configure a database for backdrop.
sql=$(
	cat <<EOF
CREATE DATABASE ${BACKDROP_DATABASE_NAME};
GRANT ALL ON ${BACKDROP_DATABASE_NAME}.* TO '${BACKDROP_DATABASE_USER}'@'localhost' IDENTIFIED BY '${BACKDROP_DATABASE_PASSWORD}';
FLUSH   PRIVILEGES;
EOF
)

if mysql --user=root --execute "$sql"; then
	systemd-cat \
		--identifier=$identifier \
		echo "Created and configured database $BACKDROP_DATABASE_NAME for $BACKDROP_DATABASE_USER@localhost."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to create the database $BACKDROP_DATABASE_NAME so exiting."
	exit 4
fi


# Settings file configuration
settings_appendages=$(
	cat <<EOF

/**
 * configure-backdrop-dev appendages
 */ 
\$settings['trusted_host_patterns'] = array(
    '^localhost:$MAPPED_PORT\$', 
    '^localhost\$',
);
\$database_charset = 'utf8mb4';
EOF
)

if (echo "$settings_appendages" >>$settings_path); then
	systemd-cat \
		--identifier=$identifier \
		echo "Updated the settings.php file."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to update the settings.php file."
	exit 5
fi

