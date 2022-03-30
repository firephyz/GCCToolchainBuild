###############################################################################
# GNU Binutils for arm-none-eabi targets.
###############################################################################
%{!?skip_download:%undefine _disable_source_fetch}
%define _unpackaged_files_terminate_build 1
%define _debugsource_packages 0
# separate, compat, so binaries are shipped with build-ids
%define _build_id_links none
%define _color_output auto
%define do_log(l:) %{?dolog:|& tee %{package_build_dir}/rpmlogs/%{-l*} > /dev/null}


###############################################################################
# Package
###############################################################################
Name:           binutils
Version:        2.34
Release:        1%{?dist}
Summary:        GNU Binutils
License:        FIXME
BuildArch:      x86_64
AutoReq:        no
BuildRequires:  gnupg2

Source0:        https://ftp.gnu.org/gnu/binutils/%{name}-%{version}.tar.xz
Source1:        https://ftp.gnu.org/gnu/binutils/%{name}-%{version}.tar.xz.sig
Source2:        https://ftp.gnu.org/gnu/gnu-keyring.gpg 


###############################################################################
# Defines
###############################################################################
%global package_extract_dir_name binutils-%{version}
%global package_extract_dir %{_builddir}/%{package_extract_dir_name}
%global package_build_dir %{package_extract_dir}-build
%global package_install_prefix %{_buildrootdir}/tools
%global package_sysroot %{_buildrootdir}


###############################################################################
# Description
###############################################################################
%description
  Packaged binutils.


###############################################################################
# Download source if necessary. Prep.
###############################################################################
%prep
%{gpgverify} --keyring='%{SOURCE2}' --signature='%{SOURCE1}' --data='%{SOURCE0}'
rm -rf %{package_build_dir}
mkdir -p %{package_build_dir}
mkdir -p %{package_build_dir}/rpmlogs


###############################################################################
# Check source signature, unpack and move into source directory.
###############################################################################
if [[ ! -e %{package_extract_dir} ]]; then
%setup -q -n %{package_extract_dir_name}
fi


###############################################################################
# Start build phase. Setup build dir, configure and build
###############################################################################
%build

cd %{package_build_dir}
%{package_extract_dir}/configure \
    --prefix=%{package_install_prefix}\
    --target=arm-none-eabi \
    --disable-nls %{do_log -lconfigure.log}
    #--with-lib-path=%{LD_LIB_PATHS} \

make %{_smp_mflags} %{do_log -lmake.log}


###############################################################################
# Start install phase, change to build dir and install files
###############################################################################
%install

cd %{package_build_dir}
DESTDIR=%{buildroot} \
INSTALL="/usr/bin/install -p" \
make install %{do_log -linstall.log}


###############################################################################
# Check
###############################################################################
%check


###############################################################################
# Clean
###############################################################################
%clean


###############################################################################
# Files
###############################################################################
%files
  %defattr(0777,-,users)

  %{package_install_prefix}/arm-none-eabi
  %{package_install_prefix}/bin

  %exclude %{package_install_prefix}/share
  %exclude %{package_install_prefix}/arm-none-eabi/lib
  %exclude %{package_install_prefix}/src


###############################################################################
# Changelog
###############################################################################
%changelog
* Tue Oct 13 2020 Kyle Burge <kyle.burge7196@gmail.com>
- Created package
