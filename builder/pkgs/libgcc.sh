#!/bin/bash

PKG_NAME=libgcc
PKG_EXTRACT_DIR_NAME=gcc-11.3.0
PKG_TARBALL_NAME=gcc-11.3.0.tar.gz
BUILD_CONFIG_INHERIT=gcc

do_pkg_setup() {
    all_opt_args="cpp_phase restore"
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1

    CFLAGS='-ffunction-sections -g -Os'
    # Make enums default to 32-bits wide to increase portability, don't optimize size.
    # CFLAGS+=' -fno-short-enums'
    BUILD_DIR=$(readlink -f ${DIR_PREFIX}/BUILD/gcc-build)
    IS_CPP_PHASE=$(test -z ${cpp_phase_args+set} && echo no || echo yes)

    case ${IS_CPP_PHASE} in
	yes )
	    CONF_TARGET=configure-target-libstdc++-v3
	    BUILD_SUBDIR=libstdc++-v3
	    FILELIST_OVERRIDE=libstdc++
	    TARBALL=libstdc++.tar.gz
	    ;;
	no )
	    CONF_TARGET=configure-target-libgcc
	    BUILD_SUBDIR=libgcc
	    ;;
    esac
    # PREFIX=${TOOL_SYSROOT}
    # save_overrides "CFLAGS PREFIX BUILD_DIR GCC_BUILD_BACKUP"
    save_overrides "CFLAGS BUILD_DIR IS_CPP_PHASE CONF_TARGET BUILD_SUBDIR"
    [ ${IS_CPP_PHASE} = yes ] && save_overrides "TARBALL FILELIST_OVERRIDE"

    # Setup multilib config
    if [[ ${TARGET} -eq arm-none-eabi ]]; then
	cp -v ${DIR_PREFIX}/../gcc-profiles/arms-profile-v7-aarch32 ${EXTRACT_DIR}/gcc/config/arm/
    fi

    # Restore from a previously saved post all-host build directory
    if [[ ! -z ${restore_args+set} ]]; then
	GCC_BUILD_BACKUP=$(dirname ${BUILD_DIR})/gcc-bootstrap-build.tar.gz
	
	if [[ ! -e ${GCC_BUILD_BACKUP} ]]; then
            echo xgcc hasn\'t been built yet && exit 1
	fi

	# Restore gcc-boostrap's backup
	rm -rf ${BUILD_DIR}/*
	mkdir -p ${BUILD_DIR}
	tar -C ${BUILD_DIR} -xf ${GCC_BUILD_BACKUP}
    fi
}

do_pkg_configure() {
    all_opt_args="fast"
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1

    # # Make sure libstdc++ libs are installed in the right place
    # if [[ yes == ${IS_CPP_PHASE} ]]; then
    # 	sed_script=$(echo '/Calculate glibcxx_toolexecdir, glibcxx_toolexeclibdir/'\
    # 			  '{:loop; n; '\
    # 			  '/glibcxx_toolexeclibdir='"'"'${toolexecdir}\/lib/{'\
    # 			  's/lib'"'"'/lib\/$(MULTISUBDIR)'"'"'/;b};'\
    # 			  'b loop}')
    # 	sed "${sed_script}" -i.old ${EXTRACT_DIR}/libstdc++-v3/configure
    # fi

    # just building target items here
    [ ! -z ${fast_args+set} ] && NBUILD_CPUS=12
    do_make ${CONF_TARGET} .
    NBUILD_CPUS=1

    # Force optimize for size. Makefile orders the flags weird and keeps stray O2's around
    if [[ no == ${IS_CPP_PHASE} ]]; then
	for f in $(find ${BUILD_DIR}/${TARGET}/ -regex ".*${BUILD_SUBDIR}/Makefile"); do
	    line_num=$(cat $f | grep -nE "^LIBGCC2_CFLAGS" | sed s/:.*//)
	    # rename the actual LIBGCC2_CFLAGS variable
	    sed ${line_num}'{s/LIBGCC2_CFLAGS/_LIBGCC2_CFLAGS_/}' -i $f
	    # alias the LIBGCC2_CFLAGS variable with a new one that filters out the unwanted flags
            sed $((${line_num} - 1))'{s/$/\nLIBGCC2_CFLAGS = $(filter-out -O2 -g,$(_LIBGCC2_CFLAGS_))/}' -i $f
	done
    fi

    # Customize target-specific Makefiles as necessary
    case ${TARGET} in
	arm-none-eabi )
	    # # Make sure arm-none-eabi libs are built with FPU support
	    # for f in $(find ${BUILD_DIR}/${TARGET}/ | grep ${BUILD_SUBDIR}/Makefile); do
	    # 	sed -i -r '/print-multi-lib/{:loop; n;/^[ \t]*flags/{s/; \\/" -mfloat-abi=hard"; \\/; b};b loop}' $f
	    # done
	    ;;
	aarch64-none-elf ) : ;;
    esac
}

do_pkg_build() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1

    case ${TARGET} in
	arm-none-eabi ) do_multi all ${TARGET}/${BUILD_SUBDIR}/ ;;
	aarch64-none-elf ) do_make all ${TARGET}/${BUILD_SUBDIR}/ ;;
    esac
}

do_pkg_install() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
     set -x

    case ${TARGET} in
	arm-none-eabi ) do_multi install ${TARGET}/${BUILD_SUBDIR}/ ;;
	aarch64-none-elf ) do_make install ${TARGET}/${BUILD_SUBDIR}/ ;;
    esac

    if [[ ${IS_CPP_PHASE} -eq yes ]]; then
	excludes="^share.*"
    fi
}
