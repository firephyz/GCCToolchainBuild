###############################################################################
# Newlib for arm-none-eabi targets.
###############################################################################
Name:           newlib
Version:        3.2.0
Release:        1%{?dist}
Summary:        Newlib C Library
License:        FIXME
BuildArch:      x86_64
AutoReq:        no
BuildRequires:  gcc-bootstrap == 10.1.0, binutils == 2.34

%undefine       _disable_source_fetch
Source0:        ftp://sourceware.org/pub/newlib/%{name}-%{version}.tar.gz
Source1:        ftp://sourceware.org/pub/newlib/sha512.sum
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

%global sourcedir %{_builddir}/%{name}-%{version}
%global builddir %{_builddir}/%{name}-%{version}-build
%global install_prefix %{?install_prefix}%{!?install_prefix: %{_prefix}}
%global num_cpus %{?num_cpus}%{!?num_cpus: %{_smp_mflags}}


###############################################################################
# Description
###############################################################################
%description
  Packaged newlib c library.


###############################################################################
# Prep
###############################################################################
%prep
cd %{_sourcedir}
%define sha512_status $(sha512sum -c %{S:1} 2>&1 | grep %{name}-%{version}.tar.gz | sed 's/.*: //' | grep OK > /dev/null; echo $?)
$([[ "%sha512_status" -eq  "1" ]] && exit 1 || :)

cd %{_builddir}
%setup -q
sed -i 's/AC_PREREQ(2\.64)/AC_PREREQ(2\.69)/' %{sourcedir}/configure.ac
mkdir -p %{builddir}


###############################################################################
# Build
###############################################################################
%build
cd %{builddir}

REG_FINI=--enable-newlib-register-fini
#MB_SUPPORT=--enable-newlib-mb
  # multibyte support
ATEXIT_DYN_ALLOC=--disable-newlib-atexit-dynamic-alloc
  # is already disabled if no syscalls?
GLOBAL_STDIO=--enable-newlib-global-stdio-streams
GLOBAL_ATEXIT=--enable-newlib-global-atexit
NANO_MALLOC=--enable-newlib-nano-malloc
OPT_SPACE=--enable-target-optspace
NO_SYSCALLS=--disable-newlib-supplied-syscalls

CONFIGURE_FLAGS=$(echo $REG_FINI $ATEXIT_DYN_ALLOC $GLOBAL_STDIO $GLOBAL_ATEXIT $NANO_MALLOC \
  $OPT_SPACE $NO_SYSCALLS)


PATH=%{install_prefix}/bin:$(echo $PATH)
%{sourcedir}/configure \
    --prefix=%{install_prefix} \
    --target=arm-none-eabi \
    --enable-multilib \
    $CONFIGURE_FLAGS

%make_build -j%{num_cpus}


###############################################################################
# Install
###############################################################################
%install
cd %{builddir}
rm -rf %{buildroot}
%make_install


###############################################################################
# Check
###############################################################################
%check


###############################################################################
# Clean
###############################################################################
%clean
cd %{_builddir}
%{!?keep_buildroot: rm -rf %{buildroot}}
rm -rf %{builddir}
rm -rf %{sourcedir}


###############################################################################
# Files
###############################################################################
%files
  %defattr(0777,-,users)

  %{install_prefix}/arm-none-eabi/include
  %{install_prefix}/arm-none-eabi/lib

  # %exclude %{install_prefix}/arm-none-eabi/lib/*.specs
  %exclude %{install_prefix}/arm-none-eabi/lib/arm/v5te


###############################################################################
# Changelog
###############################################################################
%changelog
* Tue Oct 13 2020 Kyle Burge <kyle.burge7196@gmail.com>
- Created package
