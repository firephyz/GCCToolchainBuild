#!/bin/bash

PKG_NAME=newlib
PKG_EXTRACT_DIR_NAME=newlib-4.0.0
PKG_TARBALL_NAME=newlib-4.0.0.tar.gz


# Custom overrides
CFLAGS='-ffunction-sections -g -Os'

# Adjust makefile scripts to only use a single multilib for testing
setup_for_single_multilib() {
    sed -r s/print-multi-lib/print-multi-lib\ \|\ sed\ -n\ \'2,2p\'/ -i ${EXTRACT_DIR}/Makefile.in
    sed -r s/print-multi-lib/print-multi-lib\ \|\ sed\ -n\ \'2,2p\'/ -i ${EXTRACT_DIR}/Makefile.tpl
    sed -r s/print-multi-lib/print-multi-lib\ \|\ sed\ -n\ \'2,2p\'/ -i ${EXTRACT_DIR}/config-ml.in
}

do_pkg_configure() {
    ${EXTRACT_DIR}                                                        \
	--prefix=${PREFIX}                       			  \
	--target=arm-none-eabi						  \
	--enable-multilib						  \
	--disable-shared						  \
	--enable-target-optspace                                          \
	--enable-newlib-multithread                                       \
	--disable-newlib-supplied-syscalls

    # Configure for a single multidir if testing
    echo ${1}
    case ${1} in
	single )
	    OLD_OPTS=$(set +o | sed 's/$/;/'); set +e
	    cat ${EXTRACT_DIR}/Makefile.in | grep 'print-multi-lib |'
	    [ $? -eq 1 ] && setup_for_single_multilib
	    eval "${OLD_OPTS}"
	    ;;
    esac

    # Configure for targets
    do_make configure-target .
}

do_pkg_pre_build() {
    # Modify top newlib Makefile to only install headers and not the default target libs
    for makefile in $(find . | grep -E 'arm-none-eabi/newlib/Makefile'); do
	# Get install header line number
	LN=$(cat $makefile | grep -nE 'install-data-local:.*?install-toollibLIBRARIES' | sed 's/:.*//');
	[ "x${LN}" == "x" ] && continue
	# Delete dep on install-data-local target. Also remove usage of target libs
	cat $makefile | sed ${LN}s/:.*/:/';'$(($LN+1)),$(($LN+2))d -i $makefile;
    done
}

do_pkg_build() {
    do_multi all arm-none-eabi/newlib/
    do_multi all arm-none-eabi/libgloss/
}

do_pkg_install() {
    do_make install-data-local arm-none-eabi/newlib/
    do_multi install arm-none-eabi/libgloss/
}

do_post_install_cleanup() {
    # Remove extra libs and obj files
    RMFILES=$(find ${INSTALL_DIR} ! -type d | grep arm-none-eabi/lib | grep -vE '/(crt0.o|lib(nosys|c|g|m).a)' || true)

    # Remove extra directories
    RMDIRS=$(find ${INSTALL_DIR} -type d | grep arm-none-eabi/lib | grep cpu-init || true)

    # Do remove
    RMALL="${RMFILES} ${RMDIRS}"
    [ ! -z "${RMALL}" ] && rm -rv ${RMALL} || true
}
