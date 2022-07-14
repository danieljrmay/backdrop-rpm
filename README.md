# Backdrop RPM Packaging #

[![Copr build
status](https://copr.fedorainfracloud.org/coprs/danieljrmay/backdrop/package/backdrop/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/danieljrmay/backdrop/package/backdrop/)

[Backdrop](https://backdropcms.org/) is a free and Open Source Content
Management System that helps you build modern, comprehensive websites
for businesses and non-profits.

This project provides a RPM package of Backdrop.

**Please do not use this RPM package in production — it requires more testing!**

## Installation ##

If you want to install this RPM for testing purposes then it is
available via a [Copr
repository](https://copr.fedorainfracloud.org/coprs/danieljrmay/backdrop/package/backdrop/).

If you are running Fedora you should be able to install it with:

```
# Enable the Copr repository
> sudo dnf copr enable danieljrmay/backdrop

# Install the RPM
> sudo dnf install backdrop
```

## RPM Features ##

### Filesystem Paths ###

This RPM does not install backdrop under a single directory
e.g. `/var/www/html` as would be usual when installing from
source. Instead, the RPM convention is to follow the [Filesystem
Hierarchy Standard](https://refspecs.linuxfoundation.org/fhs.shtml)
which requires that different parts of the backdrop codebase are
installed in different locations:

#### `/usr/share/backdrop` ####

This directory contains the main backdrop codebase and so any
webserver configuration for a backdrop site should specify
`DocumentRoot "/usr/share/backdrop"`.

#### `/etc/backdrop/settings.php` ####

Backdrop's `settings.php` configuration file is installed under
`/etc/backdrop`. A symbolic link of the form
`/usr/share/backdrop/settings.php -> /etc/backdrop/settings.php` means
that no other modification to the backdrop codebase is required.

#### `/etc/backdrop/sites` ####

Backdrop's `sites` directory is installed under `/etc/backdrop`. A
symbolic link of the form `/usr/share/backdrop/sites ->
/etc/backdrop/sites` means that no other modification to the backdrop
codebase is required.

#### `/var/lib/backdrop/public_files` ####

Backdrop's `files` directory is installed at `/var/lib/backdrop/public_files`. A
symbolic link of the form `/usr/share/backdrop/files ->
/var/lib/backdrop/public_files` means that no other modification to the backdrop
codebase is required.

#### `/var/lib/backdrop/private_files` ####

A directory for private files is created at
`/var/lib/backdrop/private_files`. Backdrop's
`core/modules/system/config/system.core.json` file is patched so that
this path is pre-configured as the default *private file system
path*. The *default download method* is kept as *public local files
served by the webserver*.

### SELinux ###

The `%post` scriptlet of the RPM modifies and applies the SELinux
policy as follows:

| Path                                       | SELinux Context File Type |
|:-------------------------------------------|:--------------------------|
| `/etc/backdrop/settings.php`               | `httpd_sys_content_t`     |
| `/etc/backdrop/sites/*`                    | `httpd_sys_content_t`     |
| `/usr/share/backdrop/*`                    | `httpd_sys_content_t`     |
| `/usr/share/backdrop/.htaccess`            | `httpd_config_t`          |
| `/var/lib/backdrop/private_files/*`        | `httpd_sys_rw_content_t`  |
| `/var/lib/backdrop/public_files/*`         | `httpd_sys_rw_content_t`  |
| `/var/lib/backdrop/public_files/.htaccess` | `httpd_config_t`          |

| SELinux Boolean             | Value |
|:----------------------------|:------|
| `httpd_can_sendmail`        | `on`  |
| `httpd_can_network_connect` | `on`  |

The `%postun`scriptlet of the RPM removes the above SELinux context
file types from the policy. However, it does not revert the values of the
SELinux booleans `httpd_can_sendmail` and `httpd_can_network_connect`
as this might break other applications.

## Development ##

This repositories code was originally written and tested on a Fedora
36 workstation. If you are using a different distribution then you may
need to modify the code.

The following instructions apply to Fedora.

### Building the RPM ###

```
# Install GNU Make 
> sudo dnf install make

# Get information about the available make targets
> make help

# Install the build and test requirements
> sudo make requirements

# Build the RPM
> make
```

### Testing the RPM ###

```
# Create a container image based on the latest version of Fedora with
# the Backdrop RPM installed
> make container-image

# Create a running container based on the image
> make container
```

You can complete the installation of Backdrop in your new
container by navigating to `http://localhost:48080` in a browser.

You can explore the filesystem of the running container via a Bash
shell with `make explore-container`. A typical session would look like
this:

```
> make explore-container

root@CONTAINERID> ls -lh /usr/share/backdrop
total 20K
drwxr-xr-x. 1 root root  222 Jul 14 12:49 core
lrwxrwxrwx. 1 root root   38 Jul 14 11:03 files -> ../../../var/lib/backdrop/public_files
-rw-r--r--. 1 root root  578 May 16 02:36 index.php
drwxr-xr-x. 1 root root   18 Jul 14 12:49 layouts
drwxr-xr-x. 1 root root   18 Jul 14 12:49 modules
-rw-r--r--. 1 root root 1.2K May 16 02:36 robots.txt
lrwxrwxrwx. 1 root root   34 Jul 14 11:03 settings.php -> ../../../etc/backdrop/settings.php
lrwxrwxrwx. 1 root root   27 Jul 14 11:03 sites -> ../../../etc/backdrop/sites
drwxr-xr-x. 1 root root   18 Jul 14 12:49 themes

root@CONTAINERID> mysql -ubackdrop_db_user -hlocalhost -pbackdrop_db_pwd backdrop
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 20
Server version: 10.5.16-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [backdrop]> SHOW TABLES;
+-----------------------------+
| Tables_in_backdrop          |
+-----------------------------+
| batch                       |
| cache                       |
  ⋮
| variable                    |
| watchdog                    |
+-----------------------------+
59 rows in set (0.001 sec)

MariaDB [backdrop]> QUIT;
Bye
[root@CONTAINERID> exit
> ▮
```

The default database configuration, as specified in the
`test/backdrop-firstboot.secrets` is as follows:

| Parameter         | Value              |
|:------------------|:-------------------|
| Database Name     | `backdrop`         |
| Database Username | `backdrop_db_user` |
| Database Password | `backdrop_db_pwd`  |

### Tidying Up ###

```shell
# Stop and remove the container
make delete-container

# Remove the container image
make delete-container-image

# Delete the built RPM and SRPM
make clean

# Delete all generated files, containers and container images
make distclean
```
