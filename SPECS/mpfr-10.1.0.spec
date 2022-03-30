###############################################################################
# GNU MPFR library
###############################################################################
%{!?skip_download:%undefine _disable_source_fetch}
%define _unpackaged_files_terminate_build 1
%define _debugsource_packages 0
# separate, compat, so binaries are shipped with build-ids
%define _build_id_links none
%define _color_output auto
%define do_log(l:) %{?dolog:|& tee %{_builddir}/rpmlogs/%{name}-%{-l*} > /dev/null}



###############################################################################
# Package
###############################################################################
Name:           mpfr
Version:        10.1.0
Release:        1%{?dist}
Summary:        GNU MPFR
License:        FIXME
BuildArch:      x86_64
AutoReq:        no
BuildRequires:  gnupg2

Source0:        https://ftp.gnu.org/gnu/gcc/gcc-%{version}/gcc-%{version}.tar.xz
Source1:        https://ftp.gnu.org/gnu/gcc/gcc-%{version}/gcc-%{version}.tar.xz.sig
Source2:        https://ftp.gnu.org/gnu/gnu-keyring.gpg



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
  Packaged gcc prerequisite mpfr.


  
###############################################################################
# Download source if necessary. Prep.
###############################################################################
%prep
%{gpgverify} --keyring='%{SOURCE2}' --signature='%{SOURCE1}' --data='%{SOURCE0}'
rm -rf %{package_build_dir}
mkdir -p %{package_build_dir}
mkdir -p %{_builddir}/rpmlogs



###############################################################################
# Check source signature, unpack and move into source directory.
###############################################################################
if [[ ! -e %{package_extract_dir} ]]; then
%setup -q -n %{package_extract_dir_name}
cd %{package_extract_dir}
%{package_extract_dir}/contrib/download_prerequisites
fi



###############################################################################
# Start build phase. Setup build dir, configure and build
###############################################################################
%build
cd %{package_build_dir}

F_BUILD_HOST_TARGET="\
    --build=x86_64-pc-linux-gnu \
    --host=x86_64-pc-linux-gnu \
    --target=arm-none-eabi"
F_WITH_WITHOUT="\
    --without-headers \
    --with-gmp-include=%{package_install_prefix}/include \
    --with-gmp-lib=%{package_install_prefix}/lib"
F_ENABLE_DISABLE="\
    --enable-multilib \
    --enable-languages=c,lto \
    --disable-shared \
    --disable-libssp \
    --disable-option-checking"
F_STANDARD="\
    --prefix=%{package_install_prefix}"
F_OTHER="\
    --srcdir=%{package_extract_dir}/mpfr \
    --cache-file=./config.cache \
    --program-transform-name='s&^&arm-none-eabi-&'"
F_ALL="\
    ${F_STANDARD} \
    ${F_BUILD_HOST_TARGET} \
    ${F_WITH_WITHOUT} \
    ${F_ENABLE_DISABLE} \
    ${F_OTHER}"

%{package_extract_dir}/mpfr/configure ${F_ALL} %{do_log -lconfigure.log}

# %{sourcedir}/configure \
#     --prefix=%{install_prefix} \
#     --target=arm-none-eabi \
#     --enable-languages=c \
#     --enable-multilib \
#     --without-headers \
#     --disable-libssp \
#     --with-multilib-list=@armv7-a-profile

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

  %{package_install_prefix}/lib
  %{package_install_prefix}/include

  %exclude %{package_install_prefix}/share



###############################################################################
# Changelog
###############################################################################
%changelog
* Tue Oct 13 2020 Kyle Burge <kyle.burge7196@gmail.com>
- Created package
