#!/usr/bin/bash
#
# backdrop-install
#
# Author: Daniel J. R. May
#
# This script installs backdrop using environment variables for
# configuration. This script should be called only once per backdrop
# site instance.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-rpm


declare -r identifier='backdrop-install'


# Set the values of all variables which have not been set by the
# environment.
: "${BACKDROP_DATABASE_NAME:=backdrop}"
: "${BACKDROP_DATABASE_USER:=backdrop_db_user}"
: "${BACKDROP_DATABASE_PASSWORD:=backdrop_db_pwd}"
: "${BACKDROP_DATABASE_HOST:=localhost}"
: "${BACKDROP_DATABASE_PREFIX:=}"
: "${BACKDROP_ACCOUNT_MAIL:=admin@example.com}"
: "${BACKDROP_ACCOUNT_NAME:=admin}"
: "${BACKDROP_ACCOUNT_PASSWORD:=admin_pwd}"
: "${BACKDROP_CLEAN_URL:=1}"
: "${BACKDROP_LANGCODE:=en}"
: "${BACKDROP_SITE_MAIL:=admin@example.com}"
: "${BACKDROP_SITE_NAME:=Backdrop RPM Test}"


# Install backdrop via the command line.
if ! /usr/bin/php /usr/share/backdrop/core/scripts/install.sh \
     --root=/usr/share/backdrop \
     --account-mail="$BACKDROP_ACCOUNT_MAIL" \
     --account-name="$BACKDROP_ACCOUNT_NAME" \
     --account-pass="$BACKDROP_ACCOUNT_PASSWORD" \
     --clean-url="$BACKDROP_CLEAN_URL" \
     --db-url=mysql://${BACKDROP_DATABASE_USER}:${BACKDROP_DATABASE_PASSWORD}@${BACKDROP_DATABASE_HOST}/${BACKDROP_DATABASE_NAME} \
     --langcode="$BACKDROP_LANGCODE" \
     --site-mail="$BACKDROP_SITE_MAIL" \
     --site-name="$BACKDROP_SITE_NAME"; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to install backdrop."
	exit 1
fi
