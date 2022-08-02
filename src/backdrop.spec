# Backdrop directories
%global backdrop_conf %{_sysconfdir}/%{name}
%global backdrop_data %{_datadir}/%{name}
%global backdrop_var  %{_localstatedir}/lib/%{name}
%global backdrop_private_files %{_localstatedir}/lib/%{name}/private_files
%global backdrop_public_files %{_localstatedir}/lib/%{name}/public_files

Name:           backdrop
Version:        1.22.2
Release:        2%{?dist}
Summary:        Backdrop is a free and Open Source Content Management System

License:        GPLv2
URL:            https://backdropcms.org
Source0:        https://github.com/%{name}/%{name}/releases/download/%{version}/%{name}.zip
Source1:        %{name}-vhost.conf.example
Patch0:         system.core.json.patch
BuildArch:      noarch

Requires:       httpd mariadb-server php php-fpm php-gd php-json php-mbstring php-mysqlnd php-pecl-zip php-xml
Requires(post): policycoreutils policycoreutils-python-utils
Requires(postun): policycoreutils policycoreutils-python-utils

%description
Backdrop is a free and Open Source Content Management System that
helps you build modern, comprehensive websites for businesses and
non-profits.

%prep
%setup -q -n %{name}
%patch0 -p1
cp  --preserve %{SOURCE1} .

%build
# Nothing to do

%install
install --directory %{buildroot}%{backdrop_conf}
install --directory %{buildroot}%{backdrop_data}
install --directory %{buildroot}%{backdrop_private_files}
install --directory %{buildroot}%{backdrop_public_files}
cp --preserve --recursive --target-directory=%{buildroot}%{backdrop_conf} settings.php sites
cp --preserve --recursive --target-directory=%{buildroot}%{backdrop_data} core .htaccess index.php layouts modules robots.txt themes
cp --preserve --target-directory=%{buildroot}%{backdrop_public_files} files/.htaccess files/README.md
ln --symbolic --target-directory=%{buildroot}%{backdrop_data} ../../../etc/%{name}/settings.php
ln --symbolic --target-directory=%{buildroot}%{backdrop_data} ../../../etc/%{name}/sites
ln --symbolic ../../../var/lib/%{name}/public_files %{buildroot}%{backdrop_data}/files
install --directory %{buildroot}%{_sysconfdir}/httpd/conf.d
install --target-directory=%{buildroot}%{_sysconfdir}/httpd/conf.d %{name}-vhost.conf.example

%post
semanage fcontext --add --type httpd_sys_content_t '%{backdrop_conf}/settings\.php' 2>/dev/null || :
semanage fcontext --add --type httpd_sys_content_t '%{backdrop_conf}/sites(/.*)' 2>/dev/null || :
semanage fcontext --add --type httpd_sys_content_t '%{backdrop_data}/(.*)' 2>/dev/null || :
semanage fcontext --add --type httpd_config_t '%{backdrop_data}/\.htaccess' 2>/dev/null || :
semanage fcontext --add --type httpd_sys_rw_content_t '%{backdrop_private_files}/(.*)' 2>/dev/null || :
semanage fcontext --add --type httpd_sys_rw_content_t '%{backdrop_public_files}/(.*)' 2>/dev/null || :
semanage fcontext --add --type httpd_config_t '%{backdrop_public_files}/\.htaccess' 2>/dev/null || :
restorecon -R %{backdrop_conf} %{backdrop_data} %{backdrop_var} || :
setsebool -P httpd_can_sendmail=on httpd_can_network_connect=on || :

%postun
if [ $1 -eq 0 ] ; then  # final removal
semanage fcontext --delete --type httpd_sys_content_t '%{backdrop_conf}/settings\.php' 2>/dev/null || :
semanage fcontext --delete --type httpd_sys_content_t '%{backdrop_conf}/sites(/.*)' 2>/dev/null || :
semanage fcontext --delete --type httpd_sys_content_t '%{backdrop_data}/(.*)' 2>/dev/null || :
semanage fcontext --delete --type httpd_config_t '%{backdrop_data}/\.htaccess' 2>/dev/null || :
semanage fcontext --delete --type httpd_sys_rw_content_t '%{backdrop_private_files}/(.*)' 2>/dev/null || :
semanage fcontext --delete --type httpd_sys_rw_content_t '%{backdrop_public_files}/(.*)' 2>/dev/null || :
semanage fcontext --delete --type httpd_config_t '%{backdrop_public_files}/\.htaccess' 2>/dev/null || :
# We do not revert the SELinux booleans which we configured in %post
# because they may be used by other applications which we would break.
# They can be reverted manually by issuing the following command as an
# administrative user:
#
# > setsebool -P httpd_can_sendmail=off httpd_can_network_connect=off
fi

%files
%doc README.md
%license LICENSE.txt
%dir %{backdrop_conf}
%config(noreplace) %attr(664,root,apache) %{backdrop_conf}/settings.php
%dir %{backdrop_conf}/sites
%config(noreplace) %{backdrop_conf}/sites/sites.php
%{backdrop_conf}/sites/README.md
%dir %{backdrop_data}
%config(noreplace) %{backdrop_data}/.htaccess
%config(noreplace) %{backdrop_data}/settings.php
%{backdrop_data}/core
%{backdrop_data}/files
%{backdrop_data}/index.php
%{backdrop_data}/layouts
%{backdrop_data}/modules
%{backdrop_data}/robots.txt
%{backdrop_data}/sites
%{backdrop_data}/themes
%dir %{backdrop_var}
%dir %attr(775,root,apache) %{backdrop_private_files}
%dir %attr(775,root,apache) %{backdrop_public_files}
%config(noreplace) %{backdrop_public_files}/.htaccess
%doc %{backdrop_public_files}/README.md
%{_sysconfdir}/httpd/conf.d/%{name}-vhost.conf.example

%changelog
* Tue Aug  2 2022 Daniel J. R. May <daniel.may@kada-media.com> - 1.22.2-2
- Remove backdropctl script, replaced by backdrop/core/scripts.

* Fri Jul 22 2022 Daniel J. R. May <daniel.may@kada-media.com> - 1.22.2-1
- Upstream release.

* Wed May 18 2022 Daniel J. R. May <daniel.may@kada-media.com> - 1.22.0-1
- Upstream release.
- Add private files directory and configuration.

* Thu May 12 2022 Daniel J. R. May <daniel.may@kada-media.com> - 1.21.4-1
- Initial release.
