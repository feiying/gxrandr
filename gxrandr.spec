Name:    gxrandr
Version: 2.3
Release: 1%{?dist}
Summary: a simple utility to switch monitor-projceter schemas.
Group:   Applications/System
License: GPL
URL:     http://blog.csdn.net/smfwuxiao

Source0: gxrandr-%{version}.tar.gz

Requires: xorg-x11-server-utils
Requires: grep
Requires: gawk
Requires: bash
Requires: gtk2

BuildRequires: gtk2-devel
BuildRequires: desktop-file-utils

%description
A simple utility to switch monitor-projceter schemas.
There are 4 schmeas at the moment.

%prep
%setup -q

%build

cd src
make
cd ..
rm -rf $RPM_BUILD_ROOT

%install

install -d $RPM_BUILD_ROOT/usr/share/gxrandr/images
install -d $RPM_BUILD_ROOT/usr/bin

cp src/gxrandr $RPM_BUILD_ROOT/usr/bin
cp share/*.png $RPM_BUILD_ROOT/usr/share/gxrandr/images
cp share/icon.png $RPM_BUILD_ROOT/usr/share/gxrandr

desktop-file-install --delete-original \
	--dir %{buildroot}%{_datadir}/applications \
	share/gxrandr-hardware.desktop
	
desktop-file-install --delete-original \
	--dir %{buildroot}%{_datadir}/applications \
	share/gxrandr-systemapp.desktop

%files
/usr/bin/gxrandr
/usr/share/gxrandr
%{_datadir}/applications/gxrandr-hardware.desktop
%{_datadir}/applications/gxrandr-systemapp.desktop

%changelog
* Sat Apr 28 2012 Wu Xiao <xiao.wu@cs2c.com.cn> 2.3
- adjust user interface a little.

* Tue Feb 28 2012 Wu Xiao <xiao.wu@cs2c.com.cn> 2.2
- change its entry to system->administration

* Fri Feb 17 2012 Wu Xiao <xiao.wu@cs2c.com.cn> 2.1
- a fresh-looking layout is used making it looks cool enough.

* Thu Jan 5 2012 Wu Xiao <xiao.wu@cs2c.com.cn> 2.0
- A new technology used and the bug about resolution difference is fixed.

* Mon Dec 26 2011 Wu Xiao <xiao.wu@cs2c.com.cn> 1.2
- add a close button.
- disable the automatic exit behavior.

* Fri Dec 16 2011 Wu Xiao <xiao.wu@cs2c.com.cn> 1.0
- started
