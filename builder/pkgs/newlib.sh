#!/bin/bash

PKG_NAME=newlib
PKG_EXTRACT_DIR_NAME=newlib-4.1.0
PKG_TARBALL_NAME=newlib-4.1.0.tar.gz

do_pkg_setup() {
    all_opt_args="single bootstrap target"
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1

    CFLAGS='-ffunction-sections -g -Os'
    # CFLAGS+=' -fno-short-enums'
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

    save_overrides "CFLAGS PREFIX TARGET PKG_EXTRA_TAR_INFO"

    # Override source for a single multidir if testing
    if [[ ! -z ${single_args+_} ]]; then
	sed_string=/print-multi-lib' \| 'sed/\!s/print-multi-lib/print-multi-lib' | 'sed\ -n\ \'2,4p\'/
	sed -r "${sed_string}" -i ${EXTRACT_DIR}/Makefile.in
	sed -r "${sed_string}" -i ${EXTRACT_DIR}/Makefile.tpl
	sed -r "${sed_string}" -i ${EXTRACT_DIR}/config-ml.in
    fi

    # newlib uses '<target>-cc' instead of '<target>-gcc' so create a symlink to our gcc
    GCC_DIR=$(readlink -f ${TOOL_SYSROOT}/bin)
    [ -L ${LOCAL_BUILD_ROOT}/bin/${TARGET}-cc ] || ln -sv ${GCC_DIR}/${TARGET}-gcc ${LOCAL_BUILD_ROOT}/bin/${TARGET}-cc
}

do_pkg_configure() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    ${EXTRACT_DIR}/configure                                              \
	--prefix=${PREFIX}                       			  \
	--target=${TARGET}						  \
	--enable-multilib						  \
	--disable-shared						  \
	--enable-target-optspace                                          \
	--enable-newlib-multithread                                       \
	--disable-newlib-supplied-syscalls                                \
	--disable-newlib-fvwrite-in-streamio                              \
        --disable-newlib_io_float					  \
        --disable-newlib-mb						  \
        --disable-newlib-wide-orient                                      \
	--enable-newlib-nano-malloc                                       \
        --enable-lite-exit						  \
        --enable-newlib-nano-malloc					  \
        --disable-newlib-register-fini					  \
        --disable-newlib-atexit-dynamic-alloc				  \
        --disable-newlib-global-atexit					  \
        --disable-newlib-global-stdio-streams				  \
        --disable-newlib-fseek-optimization                               \
	;
}

do_pkg_pre_build() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    do_make configure-target .

    # Modify generated newlib Makefile to only install headers and
    # don't require the target libs to have been built before.
    for makefile in $(find . | grep -E ${TARGET}/newlib/Makefile); do
	# Get install header line number
	LN=$(cat $makefile | grep -nE 'install-data-local:.*?install-toollibLIBRARIES' | sed 's/:.*//');
	[ "x${LN}" == "x" ] && continue
	# Delete dep on install-data-local target. Also remove usage of target libs
	cat $makefile | sed ${LN}s/:.*/:/';'$(($LN+1)),$(($LN+2))d -i $makefile;
    done

    # # Make sure arm-none-eabi libs are built with FPU support
    # if [[ ${TARGET} == arm-none-eabi ]]; then
    # 	for f in $(find ${BUILD_DIR}/${TARGET}/ | grep -E "(newlib|libgloss)/Makefile"); do
    # 	    sed -i -r '/print-multi-lib/{:loop; n;/^[ \t]*flags/{s/; \\/" -mfloat-abi=hard"; \\/; b};b loop}' $f
    # 	done
    # fi
}

do_pkg_build() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    case ${TARGET} in
	arm-none-eabi ) do_multi all ${TARGET}/newlib/ ;;
	aarch64-none-elf ) do_make all ${TARGET}/newlib/ ;;
    esac

    # libgloss doesn't enable the _LITE_EXIT define when using --enable-lite_exit
    CFLAGS="${CFLAGS} -D_LITE_EXIT"
    case ${TARGET} in
	arm-none-eabi ) do_multi all ${TARGET}/libgloss/ ;;
	aarch64-none-elf ) do_make all ${TARGET}/libgloss/ ;;
    esac
}

do_pkg_install() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1

    case ${TARGET} in
	arm-none-eabi )
	    do_make install-data-local ${TARGET}/newlib/
	    do_multi install ${TARGET}/libgloss/
	    ;;
	aarch64-none-elf )
	    do_make install ${TARGET}/newlib/
	    do_make install ${TARGET}/libgloss/
	    ;;
    esac

    case ${TARGET} in
	arm-none-eabi )
	    unneeded_objs='iq80310.specs|linux.specs|nano.specs|aprofile-ve-v2m.specs
                          |redboot.specs|rdimon.specs|aprofile-ve.specs|aprofile-validation.specs
                          |pid.specs|aprofile-validation-v2m.specs|rdpmon.specs
                          |cpu-init|redboot-crt0.o|linux-crt0.o|redboot-crt0.o
                          |rdimon-v2m.specs|librdimon-v2m.a|librdpmon.a|librdimon.a
                          |rdimon-crt0-v2m.o|rdimon-crt0.o|rdpmon-crt0.o|libgloss-linux.a
                          |redboot.ld|redboot-syscalls.o'
	    multidirs="v7-r|v7-a|v8-a"
	    arm_thumb="arm|thumb"
	    hard_soft="hard|soft"
	    ;;
	aarch64-none-elf )
	    unneeded_objs='cpu-init|rdimon.specs|aem-ve.specs|aem-validation.specs
                          |librdimon.a|aem-v8-r.specs|rdimon-crt0.o'
	    multidirs=".|ilp32"
	    ;;
    esac
    unneeded_objs=$(echo ${unneeded_objs} | sed -r 's/[ ]*\|[ ]*/|/g')
    arm_thumb=${arm_thumb+(${arm_thumb})/}
    hard_soft=${hard_soft+(${hard_soft})/}
    echo ${unneeded_objs}
    excludes=".*${arm_thumb}(${multidirs})/${hard_soft}(${unneeded_objs}).*"
    echo ${excludes}
             
}
