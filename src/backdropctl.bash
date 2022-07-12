#!/usr/bin/bash
#
# backdropctl
#
# Author: Daniel J. R. May
#
# A script to help with the initial installation, securing and
# maintenance of a backdrop site installed via the backdrop RPM.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-rpm

#############
# Variables #
#############
declare -r _version='0.0.1, 13 May 2022'

# Exit codes
declare -ir _exit_status_ok=0
declare -ir _exit_status_failed_to_start_mariadb=1
declare -ir _exit_status_failed_to_secure_mariadb=2
declare -ir _exit_status_failed_to_create_db=3
declare -ir _exit_status_failed_start_httpd_php_fpm=4

# Font formating related variables for easy text decoration when
# echoing output to the console.

# Colors are represented by numbers in tput, we give these numbers
# variable names to make this script more readable.
declare -ir _font_black=0
declare -ir _font_red=1
declare -ir _font_green=2
declare -ir _font_yellow=3
declare -ir _font_blue=4
declare -ir _font_magenta=5
declare -ir _font_cyan=6
declare -ir _font_white=7

# Background colors
_font_bg_black=$(tput setab $_font_black)
readonly _font_bg_black
_font_bg_red=$(tput setab $_font_red)
readonly _font_bg_red
_font_bg_green=$(tput setab $_font_green)
readonly _font_bg_green
_font_bg_yellow=$(tput setab $_font_yellow)
readonly _font_bg_yellow
_font_bg_blue=$(tput setab $_font_blue)
readonly _font_bg_blue
_font_bg_magenta=$(tput setab $_font_magenta)
readonly _font_bg_magenta
_font_bg_cyan=$(tput setab $_font_cyan)
readonly _font_bg_cyan
_font_bg_white=$(tput setab $_font_white)
readonly _font_bg_white

# Foreground colors
_font_fg_black=$(tput setaf $_font_black)
readonly _font_fg_black
_font_fg_red=$(tput setaf $_font_red)
readonly _font_fg_red
_font_fg_green=$(tput setaf $_font_green)
readonly _font_fg_green
_font_fg_yellow=$(tput setaf $_font_yellow)
readonly _font_fg_yellow
_font_fg_blue=$(tput setaf $_font_blue)
readonly _font_fg_blue
_font_fg_magenta=$(tput setaf $_font_magenta)
readonly _font_fg_magenta
_font_fg_cyan=$(tput setaf $_font_cyan)
readonly _font_fg_cyan
_font_fg_white=$(tput setaf $_font_white)
readonly _font_fg_white

# Font styles
_font_bold=$(tput bold)
readonly _font_bold
_font_dim=$(tput dim)
readonly _font_dim
_font_start_underline=$(tput smul)
readonly _font_start_underline
_font_stop_underline=$(tput rmul)
readonly _font_stop_underline
_font_reverse=$(tput rev)
readonly _font_reverse
_font_start_standout=$(tput smso)
readonly _font_start_standout
_font_stop_standout=$(tput rmso)
readonly _font_stop_standout
_font_reset=$(tput sgr0)
readonly _font_reset

# Logging functions to ease use when echoing output to the console or
# redirecting output to a log file.

# Verbosity constants
declare -ir _verbosity_silent=0
declare -ir _verbosity_warning=1
declare -ir _verbosity_normal=2
declare -ir _verbosity_verbose=3
declare -ir _verbosity_debug=4

# The intial verbosity level, for production this should be:
_verbosity=$_verbosity_normal
# However the following line can be uncommented in development to show
# all debugging messages before the the '--debug' option flag can take
# effect
_verbosity=$_verbosity_debug

function debug {
	if [ "$_verbosity" -ge $_verbosity_debug ]; then
		echo -e "[${_font_bold}${_font_fg_blue}DEBUG${_font_reset}] $1"
	fi
}

function verbose {
	if [ "$_verbosity" -ge $_verbosity_verbose ]; then
		echo -e "[${_font_bold}${_font_fg_cyan}VERBOSE${_font_reset}] $1"
	fi
}

function msg {
	if [ "$_verbosity" -ge $_verbosity_normal ]; then
		echo -e "$1"
	fi
}

function ok {
	if [ "$_verbosity" -ge $_verbosity_normal ]; then
		echo -e "[${_font_bold}${_font_fg_green}OK${_font_reset}] $1" >&2
	fi
}

function info {
	if [ "$_verbosity" -ge $_verbosity_normal ]; then
		echo -e "[${_font_bold}${_font_fg_magenta}INFO${_font_reset}] $1" >&2
	fi
}

function warn {
	if [ "$_verbosity" -ge $_verbosity_warning ]; then
		echo -e "[${_font_bold}${_font_fg_yellow}WARNING${_font_reset}] $1" >&2
	fi
}

function error {
	echo -e "[${_font_bold}${_font_fg_red}ERROR${_font_reset}] $1" >&2
}

function error_and_exit {
	error "$1"
	exit "$2"
}

# Execute the '--help' option flag by printing help & usage information
exec_help() {
	echo 'backdropctl [OPTIONS] <COMMAND> [ARGS]'
	echo
	echo 'Options:'
	echo -e "\t-d, --debug\tPrint loads of messages (useful for debugging)"
	echo -e "\t-h, --help\tPrint this help message"
	echo -e "\t-v, --verbose\tPrint messages when running"
	echo -e "\t-V, --version\tPrint version information"
	echo
	echo 'Commands:'
	echo -e "\tinstall\t\tInstall your first backdrop site"
	echo
	echo 'Get command specific help with:'
	echo -e "\tbackdropctl <COMMAND> -h"
	echo
	echo 'For more information see <https://github.com/danieljrmay/backdrop-rpm>'
}

# Execute the '--version' option flag by printing version information
exec_version() {
	echo "backdropctl version $_version"
}

exec_install_help() {
	echo 'backdropctl install [OPTIONS] [ARGS]'
	echo
	echo 'Options:'
	echo -e "\t-d, --debug\tPrint loads of messages (useful for debugging)"
	echo -e "\t-h, --help\tPrint this help message"
	echo -e "\t-v, --verbose\tPrint messages when running"
	echo -e "\t-V, --version\tPrint version information"
	echo
	echo "Install and secure a new website based on backdrop CMS."
	echo_install_steps

	echo -e "\nFor more information see <https://github.com/danieljrmay/backdrop-rpm>"
}

echo_install_steps() {
	echo -e "\nYou will be guided through a number of steps, many of which require sudo (administrator priviledges):\n"
	echo -e "\t1. Start the mariadb database server (sudo)."
	echo -e "\t2. Run the mysql_secure_installation script to secure your database server."
	echo -e "\t3. Create a database for your backdrop website."
	echo -e "\t4. Start apache (webserver) and php-fpm (FastCGI Process Manager)."
}

# Execute the 'install' command
exec_install() {
	#debug "Executing 'install' command with arguments: $*"

	while true; do
		case "$1" in
		'-d' | '--debug')
			shift
			debug '-d | --debug option detected'
			_verbosity=$_verbosity_debug
			continue
			;;
		'-h' | '--help')
			shift
			debug '-h | --help option detected'
			exec_install_help
			exit $?
			;;
		'-v' | '--verbose')
			shift
			debug '-v | --verbose option detected'
			_verbosity=$_verbosity_verbose
			continue
			;;
		'-V' | '--version')
			shift
			debug '-V | --version option detected'
			exec_version
			exit $?
			;;
		'--')
			shift
			debug '-- option detected'
			continue
			;;
		'')
			break
			;;
		*)
			error "'$1' is not a recognised option or command, please check your syntax:"
			exec_install_help
			exit $?
			;;
		esac
	done

	echo_install_steps

	echo -e "\nLet’s get started…"

	echo -e '\n1. Start the mariadb database server. This requires sudo so you will be asked for your administrator password.'
	if sudo systemctl start mariadb.service; then
		ok 'Started mariadb server.'
	else
		error_and_exit 'Failed to start mariadb server, so exiting.' $_exit_status_failed_to_start_mariadb
	fi

	echo -e "\n2. Run the mysql_secure_installation script to secure your database server."
	if /usr/bin/mysql_secure_installation; then
		ok 'Secured the mariadb installation,'
	else
		error_and_exit 'Failed to secure the mariadb installation, so exiting.' $_exit_status_failed_to_secure_mariadb
	fi

	echo -e "\n3. Create a database for your backdrop website."
	: "${BACKDROP_DB:=backdrop}"
	: "${BACKDROP_DB_USR:=backdrop_usr}"
	: "${BACKDROP_DB_PWD:=$(date +%N%s | md5sum | base64)}"
	read -r -p "Enter backdrop database name (default=$BACKDROP_DB): " backdrop_db
	: "${backdrop_db:=$BACKDROP_DB}"
	read -r -p "Enter backdrop database username (default=$BACKDROP_DB_USR): " backdrop_db_usr
	: "${backdrop_db_usr:=$BACKDROP_DB_USR}"
	read -r -p "Enter backdrop database password (default=$BACKDROP_DB_PWD): " backdrop_db_pwd
	: "${backdrop_db_pwd:=$BACKDROP_DB_PWD}"

	echo "Database name=$backdrop_db"
	echo "Database username=$backdrop_db_usr"
	echo "Database password=$backdrop_db_pwd"

	sql=$(
		cat <<EOF
CREATE DATABASE ${backdrop_db};
GRANT ALL ON ${backdrop_db}.* TO '${backdrop_db_usr}'@'localhost' IDENTIFIED BY '${backdrop_db_pwd}';
FLUSH PRIVILEGES;
EOF
	)
	if mysql --user=root --host=localhost --password --execute "$sql"; then
		ok "Created and configured database $backdrop_db for $backdrop_db_usr@localhost."
	else
		error_and_exit "Failed to create the database $backdrop_db so exiting." $_exit_status_failed_to_create_db
	fi

	echo -e "\n4. Start apache (webserver) and php-fpm (FastCGI Process Manager)."
	if sudo systemctl start httpd.service php-fpm.service; then
		ok "Started httpd.service and php-fpm.service"
	else
		error_and_exit "Failed to start httpd.service and php-fpm.service so exiting." $_exit_status_failed_start_httpd_php_fpm
	fi

	# Firewall
	# sudo firewall-cmd --add-service=http (does not make permanent?)
	# Later do firewall-cmd --add-service=https (make permanent)

	# Temporyarily make settings.php SELinux writable before the installation phase
	# chcon -t httpd_sys_rw_content_t /etc/backdrop/settings.php
	# Before changing back with
	# restorecon /etc/backdrop/settings.php

	# HTTP Strict Transport Security configured in apache conf by default if using SSLCert
	# <VirtualHost *:443>
	# ...
	# Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"
	# ...
	# </VirtualHost>

	# Backdrop page: URL settings
	# Use HTTPS for canonical URLs
	# This option makes Backdrop use HTTPS protocol for generated
	# canonical URLs. Please note: to get it working in mixed-mode
	# (both secure and insecure) sessions, the variable https
	# should be set to TRUE in your file settings.php

	# Enable mariadb php-fpm httpd so survive accross reboots

	# Add bash completeions for this

	# Add command line parameters so that this script can be run without interaction. Challenge will be mysql_secure_installation.
}

# Process the command line arguments
while true; do
	case "$1" in
	'install')
		shift
		debug "install command detected with arguments: $*"
		exec_install "$@"
		exit $?
		;;
	'-d' | '--debug')
		shift
		debug '-d | --debug option detected'
		_verbosity=$_verbosity_debug
		continue
		;;
	'-h' | '--help')
		shift
		debug '-h | --help option detected'
		exec_help
		exit $?
		;;
	'-v' | '--verbose')
		shift
		debug '-v | --verbose option detected'
		_verbosity=$_verbosity_verbose
		continue
		;;
	'-V' | '--version')
		shift
		debug '-V | --version option detected'
		exec_version
		exit $?
		;;
	'--')
		shift
		debug '-- option detected'
		continue
		;;
	'')
		error "Illegal invokation, please check your syntax:"
		exec_help
		exit $?
		;;
	*)
		error "'$1' is not a recognised option or command, please check your syntax:"
		exec_help
		exit $?
		;;
	esac
done
