# Backdrop directories
%global backdrop_conf %{_sysconfdir}/%{name}
%global backdrop_data %{_datadir}/%{name}
%global backdrop_var  %{_localstatedir}/lib/%{name}

Name:           backdrop
Version:        1.22.0
Release:        1%{?dist}
Summary:        Backdrop is a free and Open Source Content Management System

License:        GPLv2
URL:            https://backdropcms.org
Source0:        https://github.com/%{name}/%{name}/releases/download/%{version}/%{name}.zip
Source1:        %{name}.conf
Source2:        %{name}ctl.bash
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
cp  --preserve %{SOURCE1} .
cp  --preserve %{SOURCE2} .

%build
# Nothing to do

%install
install --directory %{buildroot}%{backdrop_conf}
install --directory %{buildroot}%{backdrop_data}
install --directory %{buildroot}%{backdrop_var}
cp --preserve --recursive --target-directory=%{buildroot}%{backdrop_conf} settings.php sites
cp --preserve --recursive --target-directory=%{buildroot}%{backdrop_data} core .htaccess index.php layouts modules robots.txt themes
cp --preserve --recursive --target-directory=%{buildroot}%{backdrop_var} files
ln --symbolic --target-directory=%{buildroot}%{backdrop_data} ../../../etc/%{name}/settings.php
ln --symbolic --target-directory=%{buildroot}%{backdrop_data} ../../../etc/%{name}/sites
ln --symbolic --target-directory=%{buildroot}%{backdrop_data} ../../../var/lib/%{name}/files
install --directory %{buildroot}%{_sysconfdir}/httpd/conf.d
install --target-directory=%{buildroot}%{_sysconfdir}/httpd/conf.d %{name}.conf
install --directory %{buildroot}%{_sbindir}
install %{name}ctl.bash %{buildroot}%{_sbindir}/%{name}ctl

%post
semanage fcontext --add --type httpd_sys_content_t '%{backdrop_conf}/settings\.php' 2>/dev/null || :
semanage fcontext --add --type httpd_sys_content_t '%{backdrop_conf}/sites(/.*)' 2>/dev/null || :
semanage fcontext --add --type httpd_sys_content_t '%{backdrop_data}/(.*)' 2>/dev/null || :
semanage fcontext --add --type httpd_config_t '%{backdrop_data}/\.htaccess' 2>/dev/null || :
semanage fcontext --add --type httpd_sys_rw_content_t '%{backdrop_var}/files/(.*)' 2>/dev/null || :
semanage fcontext --add --type httpd_config_t '%{backdrop_var}/\.htaccess' 2>/dev/null || :
restorecon -R %{backdrop_conf} %{backdrop_data} %{backdrop_var} || :
setsebool -P httpd_can_sendmail=1 httpd_can_network_connect=1 || :

%postun
if [ $1 -eq 0 ] ; then  # final removal
semanage fcontext --delete --type httpd_sys_content_t '%{backdrop_conf}/settings\.php' 2>/dev/null || :
semanage fcontext --delete --type httpd_sys_content_t '%{backdrop_conf}/sites(/.*)' 2>/dev/null || :
semanage fcontext --delete --type httpd_sys_content_t '%{backdrop_data}/(.*)' 2>/dev/null || :
semanage fcontext --delete --type httpd_config_t '%{backdrop_data}/\.htaccess' 2>/dev/null || :
semanage fcontext --delete --type httpd_sys_rw_content_t '%{backdrop_var}/files/(.*)' 2>/dev/null || :
semanage fcontext --delete --type httpd_config_t '%{backdrop_var}/\.htaccess' 2>/dev/null || :
#setsebool -P httpd_can_sendmail=0 httpd_can_network_connect=0 || :
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
%dir %attr(775,root,apache) %{backdrop_var}/files
%config(noreplace) %{backdrop_var}/files/.htaccess
%{backdrop_var}/files/README.md
%config(noreplace) %{_sysconfdir}/httpd/conf.d/%{name}.conf
%{_sbindir}/%{name}ctl

%changelog
* Thu May 12 2022 Daniel J. R. May <daniel.may@danieljrmay.com> - 1.21.4-1
- Initial release.
