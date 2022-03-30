###############################################################################
# GNU GCC bootstrapping compiler for arm-none-eabi targets.
###############################################################################
Name:           libgcc-bootstrap
Version:        10.1.0
Release:        1%{?dist}
Summary:        GNU GCC
License:        FIXME
BuildArch:      x86_64
AutoReq:        no
#BuildRequires:  gcc-bootstrap == 10.1.0, binutils == 2.34
BuildRequires:  binutils == 2.34

%undefine       _disable_source_fetch
Source0:        https://ftp.gnu.org/gnu/gcc/gcc-%{version}/gcc-%{version}.tar.xz
Source1:        https://ftp.gnu.org/gnu/gcc/gcc-%{version}/gcc-%{version}.tar.xz.sig
Source2:        armv7-a-profile
Nosource:       0
Nosource:       1


###############################################################################
# Defines
###############################################################################
%define _unpackaged_files_terminate_build 1
# separate, compat, so binaries are shipped with build-ids
%define _build_id_links none
# so source and debug are combined
%define _debugsource_packages 0

%global sourcedir %{_builddir}/gcc-%{version}
%global builddir %{_builddir}/gcc-%{version}-build
%global install_prefix %{?install_prefix}%{!?install_prefix: %{_prefix}}
%global num_cpus %{?num_cpus}%{!?num_cpus: %{_smp_mflags}}


###############################################################################
# Description
###############################################################################
%description
  Packaged bootstrap gcc.


###############################################################################
# Prep
###############################################################################
%prep
#gpg --keyring %{gnu_keyring} --verify %{_sourcedir}/gcc-%{version}.tar.xz.sig

%setup -q -n gcc-%{version}
mkdir -p %{builddir}
cp -v %{S:2} %{sourcedir}/gcc/config/arm/
#%{sourcedir}/contrib/download_prerequisites


###############################################################################
# Build
###############################################################################
%build
cd %{builddir}
export PATH=%{install_prefix}/bin:$PATH
%{sourcedir}/configure \
    --prefix=%{install_prefix} \
    --target=arm-none-eabi \
    --enable-languages=c \
    --enable-multilib \
    --without-headers \
    --disable-libssp \
    --with-multilib-list=@armv7-a-profile \
    --with-gmp-include=%{install_prefix}/include \
    --with-gmp-lib=%{install_prefix}/lib \
    --with-mpc-include=%{install_prefix}/include \
    --with-mpc-lib=%{install_prefix}/lib \
    --with-mpfr-include=%{install_prefix}/include \
    --with-mpfr-lib=%{install_prefix}/lib

#%make_build -j%{num_cpus}
sed -i 's/configure-target-libgcc: maybe-all-gcc/configure-target-libgcc:/' %{builddir}/Makefile
export PATH=%{install_prefix}/bin:$PATH
make -j%{num_cpus} all-target-libgcc


###############################################################################
# Install
###############################################################################
%install
cd %{builddir}
#rm -rf %{buildroot}
# %make_install
DESTDIR=%{buildroot} && make install-strip-target-libgcc



###############################################################################
# Check
###############################################################################
%check



###############################################################################
# Clean
###############################################################################
%clean
cd %{_builddir}
# %{!?keep_buildroot: rm -rf %{buildroot}}
# rm -rf %{builddir}
rm -rf %{sourcedir}


###############################################################################
# Files
###############################################################################
%files
  %defattr(0777,-,users)

  # %%{install_prefix}/bin
  # %%{install_prefix}/lib
  # %%{install_prefix}/lib64
  # %%{install_prefix}/libexec
  # %%{install_prefix}/include
  # #%%{install_prefix}/lib/gcc/arm-none-eabi/%{version}/include
  # #%%{install_prefix}/lib/gcc/arm-none-eabi/10.1.0/plugin
  #
  # %%exclude %%{install_prefix}/lib/gcc/arm-none-eabi/%{version}/include-fixed
  # %%exclude %%{install_prefix}/lib/gcc/arm-none-eabi/%{version}/install-tools
  # %%exclude %%{install_prefix}/lib/gcc/arm-none-eabi/%{version}/plugin
  # %%exclude %%{install_prefix}/libexec/gcc/arm-none-eabi/%{version}/install-tools
  # %%exclude %%{install_prefix}/libexec/gcc/arm-none-eabi/%{version}/plugin
  # %%exclude %%{install_prefix}/share
  #
  # # %%ghost %{install_prefix}/armv7-a-profile


###############################################################################
# Changelog
###############################################################################
%changelog
* Tue Oct 13 2020 Kyle Burge <kyle.burge7196@gmail.com>
- Created package
