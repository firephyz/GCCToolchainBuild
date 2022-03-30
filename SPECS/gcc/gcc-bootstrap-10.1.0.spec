###############################################################################
# GNU GCC-Bootstrap
###############################################################################
%{!?skip_download:%undefine _disable_source_fetch}
%define _unpackaged_files_terminate_build 1
%define _debugsource_packages 0
# separate, compat, so binaries are shipped with build-ids
%define _build_id_links none
%define _color_output auto
%define do_log(l:) %{?dolog:|& tee %{package_build_dir}/rpmlogs/%{-l*}%{?logquiet: > /dev/null}}



###############################################################################
# GNU Gcc Bootstrap Compiler
###############################################################################
Name:           gcc-bootstrap
Version:        10.1.0
Release:        1%{?dist}
Summary:        GNU G
License:        FIXME
BuildArch:      x86_64
AutoReq:        no
# BuildRequires:  mpc == 10.1.0, mpfr == 10.1.0, gmp == 10.1.0
Requires:       mpc == 10.1.0, mpfr == 10.1.0, gmp == 10.1.0

Source0:        https://ftp.gnu.org/gnu/gcc/gcc-%{version}/gcc-%{version}.tar.xz
Source1:        https://ftp.gnu.org/gnu/gcc/gcc-%{version}/gcc-%{version}.tar.xz.sig
Source2:        https://ftp.gnu.org/gnu/gnu-keyring.gpg 
Source3:        armv7-a-profile



###############################################################################
# Defines
###############################################################################
%global package_extract_dir_name gcc-%{version}
%global package_extract_dir %{_builddir}/%{package_extract_dir_name}
%global package_build_dir %{package_extract_dir}-build
%global package_install_prefix %{_buildrootdir}/tools
%global package_sysroot %{_buildrootdir}



###############################################################################
# Description
###############################################################################
%description
  Packaged bootstrap gcc.


  
###############################################################################
# Download source if necessary. Prep.
###############################################################################
%prep
%{gpgverify} --keyring='%{SOURCE2}' --signature='%{SOURCE1}' --data='%{SOURCE0}'
rm -rf %{package_build_dir}
mkdir -p %{package_build_dir}
mkdir -p %{package_build_dir}/rpmlogs



###############################################################################
# Unpack and move into source directory.
###############################################################################
if [[ ! -e %{package_extract_dir} ]]; then
%setup -q -n %{package_extract_dir_name}

cd %{package_extract_dir}
cp -v %{SOURCE3} %{package_extract_dir}/gcc/config/arm/
# %%{package_extract_dir}/contrib/download_prerequisites
fi



###############################################################################
# Build
###############################################################################
%build
cd %{package_build_dir}

F_BUILD_HOST_TARGET="\
    --target=arm-none-eabi"
F_WITH_WITHOUT="\
    --without-headers \
    --with-gmp-include=%{package_install_prefix}/include \
    --with-gmp-lib=%{package_install_prefix}/lib \
    --with-mpc-include=%{package_install_prefix}/include \
    --with-mpc-lib=%{package_install_prefix}/lib \
    --with-mpfr-include=%{package_install_prefix}/include \
    --with-mpfr-lib=%{package_install_prefix}/lib"
#    --with-multilib-list=@armv7-a-profile \
F_ENABLE_DISABLE="\
    --disable-libssp"
F_STANDARD="\
    --prefix=%{package_install_prefix} \
    --enable-languages=c \
    --enable-multilib \
    --disable-shared"
F_OTHER=""
F_ALL="\
    ${F_STANDARD} \
    ${F_BUILD_HOST_TARGET} \
    ${F_WITH_WITHOUT} \
    ${F_ENABLE_DISABLE} \
    ${F_OTHER}"

%{package_extract_dir}/configure ${F_ALL} %{do_log -lconfigure.log}

# make %{_smp_mflags} all-gcc %{do_log -lmake.log}
make %{_smp_mflags} %{do_log -lmake.log}



###############################################################################
# Install
###############################################################################
%install

cd %{package_build_dir}
DESTDIR=%{buildroot} \
INSTALL="/usr/bin/install -p" \
make install %{do_log -linstall.log}
#       make install-strip-gcc %{do_log -linstall.log}



###############################################################################
# Check
###############################################################################
# %check




###############################################################################
# Clean
###############################################################################
%clean



###############################################################################
# Files
###############################################################################
# %files
#   %defattr(0777,-,users)

#   %{package_install_prefix}/bin
#   %{package_install_prefix}/lib
#   %{package_install_prefix}/lib64
#   %{package_install_prefix}/libexec
#   %{package_install_prefix}/include

#   %exclude %{package_install_prefix}/lib/gcc/arm-none-eabi/%{version}/include-fixed
#   %exclude %{package_install_prefix}/lib/gcc/arm-none-eabi/%{version}/install-tools
#   %exclude %{package_install_prefix}/lib/gcc/arm-none-eabi/%{version}/plugin
#   %exclude %{package_install_prefix}/libexec/gcc/arm-none-eabi/%{version}/install-tools
#   %exclude %{package_install_prefix}/libexec/gcc/arm-none-eabi/%{version}/plugin
#   %exclude %{package_install_prefix}/share

#   %ghost %{install_prefix}/armv7-a-profile


###############################################################################
# Changelog
###############################################################################
%changelog
* Tue Oct 13 2020 Kyle Burge <kyle.burge7196@gmail.com>
- Created package
