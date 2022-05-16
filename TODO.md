# Backdrop RPM Todo List

* [ ] Finish `backdropctl install`.
* [ ] Should we add `setsebool -P httpd_can_sendmail=0
httpd_can_nework_connect=0 || :` to the `%postun` section of the spec
file?
* [ ] Modify spec so that we install SELinux configurataion via a
      "policy module". See [Fedora
      PackagingDrafts/SELinux](https://fedoraproject.org/wiki/PackagingDrafts/SELinux)
      and [SELinux Policy Modules Packaging
      Draft](https://fedoraproject.org/wiki/SELinux_Policy_Modules_Packaging_Draft).
* [ ] We need to have some example apache vhost config files: examples
      of http & https, https only, local access only etc. Perhaps
      `backdropctl` script will help configure one for user.
* [ ] Need to modify firewall rules so that http or https is available
      outside of server if required.
* [ ] Perhaps have `backdropctl` optionally install certbot so that
      user can have https unless they are providing their own certificate.
