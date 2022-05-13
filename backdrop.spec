# Backdrop directories
%global backdrop_conf %{_sysconfdir}/%{name}
%global backdrop_data %{_datadir}/%{name}
%global backdrop_var  %{_localstatedir}/lib/%{name}

Name:           backdrop
Version:        1.21.4
Release:        1%{?dist}
Summary:        Backdrop is a free and Open Source Content Management System that helps you build modern, comprehensive websites.

License:        GPLv2
URL:            https://backdropcms.org
Source0:        https://github.com/%{name}/%{name}/releases/download/%{version}/%{name}.zip
Source1:        %{name}.conf
BuildArch:      noarch

Requires:       httpd mariadb-server php php-fpm php-gd php-json php-mbstring php-mysqlnd php-pecl-zip php-xml
#Requires(post): libselinux-utils

%description
Backdrop is a free and Open Source Content Management System that
helps you build modern, comprehensive websites for businesses and
non-profits.

%prep
%setup -q -n %{name}
cp  --preserve %{SOURCE1} .

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

%files
%doc README.md
%license LICENSE.txt
%dir %{backdrop_conf}
%config(noreplace) %{backdrop_conf}/settings.php
%dir %{backdrop_conf}/sites
%{backdrop_conf}/sites/README.md
%config(noreplace) %{backdrop_conf}/sites/sites.php
%dir %{backdrop_data}
%{backdrop_data}/core
%config(noreplace) %{backdrop_data}/.htaccess
%{backdrop_data}/index.php
%{backdrop_data}/layouts
%{backdrop_data}/modules
%{backdrop_data}/robots.txt
%{backdrop_data}/themes
%config(noreplace) %{backdrop_data}/settings.php
%dir %{backdrop_var}
%dir %{backdrop_var}/files
%{backdrop_var}/files/README.md
%config(noreplace) %{backdrop_var}/files/.htaccess
%config(noreplace) %{_sysconfdir}/httpd/conf.d/%{name}.conf

%changelog
* Thu May 12 2022 Daniel J. R. May <daniel.may@danieljrmay.com> - 1.21.4-1
- Initial release.
