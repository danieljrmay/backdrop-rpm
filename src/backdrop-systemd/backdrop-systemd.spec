Name:           backdrop-systemd
Version:        0.1.0
Release:        1%{?dist}
Summary:        Systemd services for Backdrop CMS

License:        GPLv2
URL:            https://github.com/danieljrmay/backdrop-systemd
Source0:        https://github.com/danieljrmay/backdrop-systemd/archive/refs/tags/v%{version}.tar.gz
BuildArch:      noarch

Requires:       backdrop
BuildRequires:  make systemd-rpm-macros

%description
A collection  of systemd services for Backdrop CMS.

%prep
%setup -q

%build
# Nothing to do

%install
%make_install

%files
%doc README.md
%license LICENSE
%{_bindir}/backdrop-configure-httpd
%{_bindir}/backdrop-configure-mariadb
%{_bindir}/backdrop-install
%{_unitdir}/backdrop-configure-httpd.service
%{_unitdir}/backdrop-configure-mariadb.service
%{_unitdir}/backdrop-install.service

%changelog
* Wed Aug 17 2022 Daniel J. R. May <daniel.may@kada-media.com> - 0.1.0-1
- Initial release.

