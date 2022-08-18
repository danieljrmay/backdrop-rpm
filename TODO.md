# Backdrop RPM Todo List

* [x] Create a `private_files` directory for users to use.
* [x] Should we add `setsebool -P httpd_can_sendmail=off
httpd_can_nework_connect=off || :` to the `%postun` section of the spec
file?
* [x] Automate patching of `system.core.json.patch` in Makefile.
* [x] Remove `backdropctl`, replace with
      `backdrop/core/scripts/install.sh`.
* [ ] Check SELinux configuration of `.htaccess` files in `files/config` directories.
* [ ] Add `core/scripts/*.sh` to different directory (e.g. `/usr/bin`)
      or change SELinux configuration?
* [ ] Modify spec so that we install SELinux configurataion via a
      "policy module". See [Fedora
      PackagingDrafts/SELinux](https://fedoraproject.org/wiki/PackagingDrafts/SELinux)
      and [SELinux Policy Modules Packaging
      Draft](https://fedoraproject.org/wiki/SELinux_Policy_Modules_Packaging_Draft).
* [ ] Perhaps have some example apache vhost config files: examples of
      http & https, https only, local access only etc.
* [ ] Need to modify firewall rules so that http or https is available
      outside of server if required.
* [ ] How can we automate certbot installation? Perhaps have a number
      of RPM packages e.g. backdrop-core, backdrop-certbot. Then users
      can have https via LetsEncrypt if they are not providing their
      own certificates.
* [ ] Package bee as a separate RPM.
* [ ] Backdrop cron via systemd service.
* [ ] Automatic rebuilding of RPM on backdrop release. Would need
      webhook from backdrop repository.
