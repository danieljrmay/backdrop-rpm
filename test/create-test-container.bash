#!/usr/bin/bash
#
# create-test-container
#
# Author: Daniel J. R. May
#
# This script creates a container suitable for testing the
# backdrop-rpm codebase.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-rpm

declare -r image=backdrop-rpm-test
declare -r container=$image
declare -r container_hostname=$image
declare -r mariadb_secret_name=backdrop-configure-mariadb
declare -r httpd_secret_name=backdrop-configure-httpd
declare -r install_secret_name=backdrop-install
declare -i status=0

# Overrideable Variables
: "${EXPLORE:=true}"
: "${PORT:=38080}"

trap 'podman rm -f $container; podman secret rm $mariadb_secret_name $httpd_secret_name $install_secret_name || true; exit $status' EXIT ERR

# Create the secret variables.
mariadb_secret=$(
	cat <<EOF
SECURE_MARIADB=true
MARIADB_ROOT_AT_LOCALHOST_PASSWORD='mariadb_root_at_localhost_password'
MARIADB_MYSQL_AT_LOCALHOST_PASSWORD='mariadb_mysql_at_localhost_password'
CREATE_BACKDROP_DATABASE=true
BACKDROP_DATABASE_NAME='backdrop'
BACKDROP_DATABASE_USER='backdrop_database_user'
BACKDROP_DATABASE_PASSWORD='backdrop_database_password'
EOF
)
httpd_secret=$(
	cat <<EOF
CREATE_HTTPD_CONF=true
HTTPD_CONF_PATH='/etc/httpd/conf.d/backdrop.conf'
HTTPD_CONF_TYPE='container'
DOCUMENT_ROOT='/usr/share/backdrop'
PORT=$PORT
MODIFY_SETTINGS_FILE=true
SETTINGS_FILE_PATH='/etc/backdrop/settings.php'
EOF
)
install_secret=$(
	cat <<EOF
SKIP_BACKDROP_INSTALLATION=false
BACKDROP_DATABASE_NAME='backdrop'
BACKDROP_DATABASE_USER='backdrop_database_user'
BACKDROP_DATABASE_PASSWORD='backdrop_database_password'
BACKDROP_DATABASE_HOST='localhost'
BACKDROP_DATABASE_PREFIX=''
BACKDROP_ACCOUNT_NAME='admin'
BACKDROP_ACCOUNT_PASSWORD='admin_pwd'
BACKDROP_ACCOUNT_MAIL='admin@example.com'
BACKDROP_CLEAN_URL=1
BACKDROP_LANGCODE='en'
BACKDROP_SITE_MAIL='admin@example.com'
BACKDROP_SITE_NAME='backdrop-rpm test'
EOF
)

# Check base image exists.
podman image exists "$image"

# Delete and pre-existing secrets.
podman secret rm $mariadb_secret_name $httpd_secret_name $install_secret_name || true

# Create the secrets.
echo "Creating the $mariadb_secret_name secret…"
echo "$mariadb_secret" | podman secret create "$mariadb_secret_name" -
echo "Creating the $httpd_secret_name secret…"
echo "$httpd_secret" | podman secret create "$httpd_secret_name" -
echo "Creating the $install_secret_name secret…"
echo "$install_secret" | podman secret create "$install_secret_name" -

# Create and start the container.
podman run \
	--name "$container" \
	--secret source="$mariadb_secret_name",type=mount,mode=400,target="$mariadb_secret_name" \
	--secret source="$httpd_secret_name",type=mount,mode=400,target="$httpd_secret_name" \
	--secret source="$install_secret_name",type=mount,mode=400,target="$install_secret_name" \
	--hostname "$container_hostname" \
	--publish "$PORT:80" \
	--detach \
	"$image"

# Monitor the container's startup.
echo -n 'Waiting for the container to finish installing backdrop.'
while true; do
	sleep 1s

	if ! podman exec "$container" /usr/bin/systemctl is-active httpd.service >/dev/null; then
		echo -n '.'
		continue
	fi

	if podman exec "$container" \
		/usr/bin/systemctl is-failed \
		backdrop-configure-mariadb.service \
		backdrop-configure-httpd.service \
		backdrop-install.service >/dev/null; then
		podman exec "$container" /usr/bin/journalctl
		echo -e "\nERROR: backdrop installation has failed. Please check the above container logs."
		status=100
	else
		echo -e "\nThe backdrop installation should be available at http://localhost:${PORT} now."
	fi

	break
done

# Explore the container (and pause deletion of it) if requested.
if [ "$EXPLORE" = true ]; then
	echo "The environment variable EXPLORE=$EXPLORE so you can now explore the running container:"
	podman exec \
		--interactive \
		--tty \
		"$container" \
		/usr/bin/bash
else
	echo "The environment variable EXPLORE=$EXPLORE, so the container will be deleted."
fi

# Activates the trap at the beginning of this script.
exit $status
