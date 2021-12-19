#!/bin/bash
set -e

rpm-dev-path() {
    RPMBUILD_DIR=/home/builder/rpmbuild
    echo $(readlink -f ${RPMBUILD_DIR}/"${1}")
}

# Config globals
# TARGET_SYSROOT=/custom
TARGET_SYSROOT=$(rpm-dev-path BUILDROOT/root)
TOOL_SYSROOT=$(rpm-dev-path BUILDROOT/tools)
CFLAGS=

# Constants
SCRIPT_PATH=$(readlink -f ${0})
SOURCE_DIR=$(rpm-dev-path SOURCES)
PKG_DIR=$(rpm-dev-path pkgs)
LOCAL_BUILD_ROOT=$(rpm-dev-path .buildroot)

# Runtime globals
NBUILD_CPUS=1

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
    [ -z ${OVERRIDE_FILE} ] && OVERRIDE_FILE=${PKG_NAME}
    OVERRIDE_FILE_PATH=${LOCAL_BUILD_ROOT}/state/${OVERRIDE_FILE}.overrides
    [ -e ${OVERRIDE_FILE_PATH} ] && eval $(cat ${OVERRIDE_FILE_PATH})

    # Set useful variables
    [ -z ${BUILD_DIR+set}   ] && BUILD_DIR=$(rpm-dev-path BUILD/${PKG_NAME}-build)
    EXTRACT_DIR=$(rpm-dev-path BUILD/${PKG_EXTRACT_DIR_NAME})
    INSTALL_DIR=$(rpm-dev-path BUILD/${PKG_NAME}-install)
    FILELIST=$(rpm-dev-path scripts/filelists//${PKG_NAME}-${PKG_EXTRA_TAR_INFO}.f)
    # Fix tarball extra info suffix (if present) with an extra dash
    if [[ ! -z ${PKG_EXTRA_TAR_INFO} ]]; then
	PKG_EXTRA_TAR_INFO="-${PKG_EXTRA_TAR_INFO}"
    fi
    TARBALL=${PKG_NAME}${PKG_EXTRA_TAR_INFO}.tar.gz     

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
    *) echo Unknown command && exit 1;;
esac

# Load the package and setup for the build
pre_build_pkg_setup

# Execute the requested command
eval ${action_clbk} \'"${extra_args}"\'
