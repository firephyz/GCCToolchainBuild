###############################################################################
# GNU GCC-Bootstrap Libs
###############################################################################
%{!?skip_download:%undefine _disable_source_fetch}
%define _unpackaged_files_terminate_build 1
%define _debugsource_packages 0
# separate, compat, so binaries are shipped with build-ids
%define _build_id_links none
%define _color_output auto
%define do_log(l:) %{?dolog:|& tee %{package_build_dir}/rpmlogs/%{-l*}%{?logquiet: > /dev/null}}



###############################################################################
# GNU Gcc Bootstrap Compiler Libs
###############################################################################
Name:           gcc-bootstrap-libs
Version:        10.1.0
Release:        1%{?dist}
Summary:        GNU G
License:        FIXME
BuildArch:      x86_64
AutoReq:        no
BuildRequires:  gcc-bootstrap
# Requires:       mpc == 10.1.0, mpfr == 10.1.0, gmp == 10.1.0


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
  Packaged bootstrap gcc libs.


###############################################################################
# Check
###############################################################################
%define __strip %{package_install_prefix}/bin/arm-none-eabi-strip
%check


###############################################################################
# Files
###############################################################################
%files
  %defattr(0777,-,users)

  %exclude %{package_install_prefix}/bin
  %{package_install_prefix}/lib
  %{package_install_prefix}/lib64
  %{package_install_prefix}/libexec
  %exclude %{package_install_prefix}/libexec/gcc/arm-none-eabi/%{version}
  %{package_install_prefix}/include

  %exclude %{package_install_prefix}/lib/gcc/arm-none-eabi/%{version}/include-fixed
  %exclude %{package_install_prefix}/lib/gcc/arm-none-eabi/%{version}/install-tools
  %exclude %{package_install_prefix}/lib/gcc/arm-none-eabi/%{version}/plugin
  %exclude %{package_install_prefix}/libexec/gcc/arm-none-eabi/%{version}/install-tools
  %exclude %{package_install_prefix}/libexec/gcc/arm-none-eabi/%{version}/plugin
  %exclude %{package_install_prefix}/share

  %ghost %{install_prefix}/armv7-a-profile


###############################################################################
# Changelog
###############################################################################
%changelog
* Tue Oct 13 2020 Kyle Burge <kyle.burge7196@gmail.com>
- Created package
