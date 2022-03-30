#!/bin/bash

PKG_NAME=gcc
PKG_EXTRACT_DIR_NAME=gcc-10.1.0
PKG_TARBALL_NAME=gcc-10.1.0.tar.xz

do_pkg_setup() {
    all_opt_args="support_libs target single bootstrap"
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
	* ) echo Invalid target name ${target_args} && exit 1 ;;
    esac
    [ set == "${PKG_EXTRA_TAR_INFO+set}" ] && PKG_EXTRA_TAR_INFO="${PKG_EXTRA_TAR_INFO}-"
    PKG_EXTRA_TAR_INFO="${PKG_EXTRA_TAR_INFO}${TARGET}"
    GCC_BUILD_BACKUP=$(dirname ${BUILD_DIR})/gcc-bootstrap-build.tar.gz
    IS_BOOTSTRAP=${bootstrap_args+yes}
    save_overrides "CFLAGS PREFIX TARGET IS_BOOTSTRAP PKG_EXTRA_TAR_INFO GCC_BUILD_BACKUP"

    # Override source for a single multidir if testing
    if [[ ! -z ${single_args+_} ]]; then
	sed_string=/print-multi-lib' \| 'sed/\!s/print-multi-lib/print-multi-lib' | 'sed\ -n\ \'2,4p\'/
	sed -r "${sed_string}" -i ${EXTRACT_DIR}/Makefile.in
	sed -r "${sed_string}" -i ${EXTRACT_DIR}/Makefile.tpl
	sed -r "${sed_string}" -i ${EXTRACT_DIR}/config-ml.in
    	sed -r "${sed_string}" -i ${EXTRACT_DIR}/gcc/Makefile.in
    fi

    # Setup multilib config
    if [[ ${TARGET} -eq arm-none-eabi ]]; then
	cp -v $(rpm-dev-path scripts/gcc-profiles/arms-profile-aarch32) ${EXTRACT_DIR}/gcc/config/arm/
    fi

    # unpack or build support libs if necessary
    if [[ ! -z ${support_libs_args+_} ]]; then
	pushd ${BUILD_DIR}
	tar -C ${LOCAL_BUILD_ROOT} -xf ${PKG_DIR}/gcc-build-support.tar.gz
	popd
    else
	# download prereqs if we aren't supplying the support libraries
	pushd ${EXTRACT_DIR}
	${EXTRACT_DIR}/contrib/download_prerequisites

	popd
    fi
}

do_pkg_configure() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    # Setup build support library flags
    if [[ -e ${LOCAL_BUILD_ROOT}/lib/libgmp.a ]]; then
        SUPPORT_LIB_FLAGS=$(echo --with-gmp=${LOCAL_BUILD_ROOT} \
	                       --with-mpfr=${LOCAL_BUILD_ROOT} \
	                       --with-mpc=${LOCAL_BUILD_ROOT})
    else
        SUPPORT_LIB_FLAGS=""
    fi

    case ${TARGET} in
	arm-none-eabi ) multilib_select=@arms-profile-aarch32 ;;
	aarch64-none-elf ) multilib_select=ilp32,lp64 ;;
	* ) echo Invalid target ${TARGET} && exit 1 ;;
    esac

    if [[ ! -z ${IS_BOOTSTRAP} ]]; then
	GCC_CUSTOM_ARGS="--without-headers --enable-languages=c,c++"
    else
	# GCC_CUSTOM_ARGS="--enable-languages=c,c++ --with-newlib --disable-hosted-libstdcxx"
	GCC_CUSTOM_ARGS="--enable-languages=c,c++ --without-headers --disable-hosted-libstdcxx"
    fi

    # configure the package
    ${EXTRACT_DIR}/configure                                                      \
	--prefix=${PREFIX}                       			          \
	--target=${TARGET}						          \
	--enable-multilib							  \
	--disable-shared							  \
	--disable-libssp                                                          \
	--disable-libquadmath                                                     \
	--disable-tm-clone-registry                                               \
	--with-multilib-list=${multilib_select}                                   \
	${GCC_CUSTOM_ARGS}                                                        \
	${SUPPORT_LIB_FLAGS}
}

do_pkg_pre_build() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    # Just building the host tools here
    do_make configure-host .
}

do_pkg_build() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    # Just building the host tools here
    do_make all-host .

    # Save copy of the build directory for libgcc
    pushd $(dirname ${BUILD_DIR})
    tar -C ${BUILD_DIR} -czvf ${GCC_BUILD_BACKUP} .
    popd
}

do_pkg_install() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    do_make install-strip-host .

    excludes=".*lib/gcc/${TARGET}/10.1.0/install-tools.*
              .*lib/gcc/${TARGET}/10.1.0/plugin.*
	      .*share.*
	      .*libexec/gcc/${TARGET}/10.1.0/plugin.*
	      .*libexec/gcc/${TARGET}/10.1.0/install-tools.*"
}
