#!/bin/bash

PKG_NAME=binutils
PKG_EXTRACT_DIR_NAME=binutils-2.38
PKG_TARBALL_NAME=binutils-2.38.tar.gz

do_pkg_setup() {
    all_opt_args="target bootstrap"
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1

    CFLAGS='-O2'
    if [[ ! -z ${bootstrap_args+set} ]]; then
	PREFIX=${TOOL_SYSROOT}
	PKG_EXTRA_TAR_INFO=bootstrap
    else
	PREFIX=${TARGET_SYSROOT}
    fi

    # Set target
    case ${target_args} in
	arm-none-eabi ) TARGET=arm-none-eabi ;;
	aarch64-none-elf ) TARGET=aarch64-none-elf ;;
	* ) echo Invalid target name ${target_args} >&2 && exit 1 ;;
    esac
    [ set == "${PKG_EXTRA_TAR_INFO+set}" ] && PKG_EXTRA_TAR_INFO="${PKG_EXTRA_TAR_INFO}-"
    PKG_EXTRA_TAR_INFO="${PKG_EXTRA_TAR_INFO}${TARGET}"

    save_overrides "CFLAGS PREFIX TARGET PKG_EXTRA_TAR_INFO"
}

do_pkg_configure() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    ${EXTRACT_DIR}/configure \
	--prefix=${PREFIX}\
	--target=${TARGET} \
	--disable-nls
}

do_pkg_build() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    do_make all .
}

do_pkg_install() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    do_make install-strip .

    excludes=".*${PREFIX}/(share).*
	      .*tools/aarch64-none-elf/lib/ldscripts/(aarch64elf(32){0,1}b|armelfb|armelf).*"
}
