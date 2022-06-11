#!/bin/bash
set -e

# Config globals
DIR_PREFIX=/home/kyle/dev/GCCToolchainBuild/build
TARGET_SYSROOT=${DIR_PREFIX}/root
TOOL_SYSROOT=${DIR_PREFIX}/tools-sysroot
CFLAGS=

# Constants
SCRIPT_PATH=$(readlink -f ${0})
SOURCE_DIR=${DIR_PREFIX}/sources
PKG_DIR=${DIR_PREFIX}/pkgs
LOCAL_BUILD_ROOT=${DIR_PREFIX}/.buildroot

# Runtime globals
NBUILD_CPUS=8

# processes input script args
process_args() {
    pkgname=${1}
    action=${2}
    extra_args=${3}
}

pre_run_setup() {
    # Import common defs
    cd $(dirname $0)
    . do_common.sh

    # Setup runtime directories to use
    mkdir -p ${PKG_DIR}
    mkdir -p ${LOCAL_BUILD_ROOT}/{bin,lib,include,state}

    # Setup runtime variables
    PATH=${LOCAL_BUILD_ROOT}/bin:${PATH}
    PATH=${TOOL_SYSROOT}/bin:${PATH}
    PATH=${TARGET_SYSROOT}/bin:${PATH}
}

pre_build_pkg_setup() {
    # check for the no-package case
    [ -z "${pkgname}" ] && return 0

    # Load the requested package
    . pkgs/${pkgname}.sh

    # # Load pkg-specific overrides
    BUILD_CONFIG_FILE=${PKG_NAME}
    BUILD_CONFIG_FILE_PATH=${LOCAL_BUILD_ROOT}/state/${BUILD_CONFIG_FILE}.overrides
    if [[ ! -f ${BUILD_CONFIG_FILE_PATH} ]]; then
	if [[ ! -z ${BUILD_CONFIG_INHERIT} ]]; then
	    cp -v ${LOCAL_BUILD_ROOT}/state/${BUILD_CONFIG_INHERIT}.overrides ${BUILD_CONFIG_FILE_PATH}
	else
	    touch ${BUILD_CONFIG_FILE_PATH}
	fi
    fi
    eval $(cat ${BUILD_CONFIG_FILE_PATH})

    # Set useful variables
    [ -z ${BUILD_DIR+set} ] && BUILD_DIR=${DIR_PREFIX}/BUILD/${PKG_NAME}-build
    EXTRACT_DIR=${DIR_PREFIX}/BUILD/${PKG_EXTRACT_DIR_NAME}
    INSTALL_DIR=${DIR_PREFIX}/BUILD/${PKG_NAME}-install
    if [[ ${FILELIST_OVERRIDE+set} == set ]]; then
	FILELIST_NAME=${FILELIST_OVERRIDE}-${PKG_EXTRA_TAR_INFO}.f
    else
	FILELIST_NAME=${PKG_NAME}-${PKG_EXTRA_TAR_INFO}.f
    fi
    [ -z ${FILELIST} ] && FILELIST=${DIR_PREFIX}/filelists/${FILELIST_NAME}
    # Fix tarball extra info suffix (if present) with an extra dash
    if [[ ! -z ${PKG_EXTRA_TAR_INFO} ]]; then
	PKG_EXTRA_TAR_INFO="-${PKG_EXTRA_TAR_INFO}"
    fi
    [ -z ${TARBALL} ] && TARBALL=${PKG_NAME}${PKG_EXTRA_TAR_INFO}.tar.gz     

    # Setup the runtime environment
    mkdir -p ${BUILD_DIR}
    mkdir -p ${INSTALL_DIR}
    
    cd ${BUILD_DIR}
}


####################################################################################################
# Start of the script
####################################################################################################

# Setup pre-run runtime
pre_run_setup

# Process the args and requested action
process_args "$@"
case ${action} in
    setup )               action_clbk=do_setup               ;;
    # preconfigure|pcfg )   action_clbk=do_pre_configure       ;;
    configure|cfg )       action_clbk=do_configure           ;;
    prebuild|pbld )       action_clbk=do_pre_build           ;;
    build )               action_clbk=do_build               ;;
    make_install|minst )  action_clbk=do_make_install        ;;
    install )             action_clbk=do_install             ;;
    package|pkg )         action_clbk=do_package             ;;
    all )                 action_clbk=do_all                 ;;
    clean )               action_clbk=do_clean               ;;
    make )                action_clbk=do_manual_make         ;;
    call )                action_clbk=do_manual_call         ;;
    *)
	echo Unknown command
	echo "  Available commands:
    setup
    configure (cfg)
    prebuild (pbld)
    build
    make_install (minst)
    install
    package (pkg)
    all
    clean
    make
    call"
	exit 1
esac

# Load the package and setup for the build
pre_build_pkg_setup

# Execute the requested command
eval ${action_clbk} \'"${extra_args}"\'
