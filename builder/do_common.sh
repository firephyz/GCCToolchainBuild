####################################################################################################
# Make functions
####################################################################################################
MAKEFLAGS="DESTDIR=\$(readlink -f \${INSTALL_DIR}) \
	   CFLAGS=\"\${CFLAGS}\" \
	   CCASFLAGS=\"\${CFLAGS}\""
EXTRA_MAKE_FLAGS="${USER_MAKE_FLAGS}"

do_make() {
    target=${1}; workdir=${2}
    eval "make ${MAKEFLAGS} ${EXTRA_MAKE_FLAGS} -C ${workdir} ${target} -j${NBUILD_CPUS}"
}

do_multi() {
    target=${1}; workdir=${2}
    eval "make ${USER_MAKE_FLAGS} ${MAKEFLAGS} DO=${target} -C ${workdir} -j${NBUILD_CPUS} multi-do"
}

####################################################################################################
# Common targets
####################################################################################################
do_setup() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}" "do_pkg_setup") && eval "${arg_list}" || exit 1

    # Extract the source
    if [[ ! -d ${EXTRACT_DIR} ]]; then
	tar -C $(dirname ${EXTRACT_DIR}) -xf ${SOURCE_DIR}/${PKG_TARBALL_NAME}
    fi

    # Call pkg setup hook
    type do_pkg_setup 2>1 1>/dev/null && do_pkg_setup "${do_pkg_setup_subargs}" || true
}

do_configure() {
    all_opt_args=""
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}" do_pkg_configure) && eval "${arg_list}" || exit 1
    
    type do_pkg_configure 2>1 1>/dev/null && do_pkg_configure "${do_pkg_configure_subargs}" || true
}

do_pre_build() {
    all_opt_args="fast"
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}" do_pkg_pre_build) && eval "${arg_list}" || exit 1

    # Enable parallel prebuilds if desired
    if [[ ! -z ${fast_args+_} ]]; then
	NBUILD_CPUS=12
    fi
    
    type do_pkg_pre_build 2>1 1>/dev/null && do_pkg_pre_build "${do_pkg_pre_build_subargs}" || true
    NBUILD_CPUS=1
}

do_build() {
    all_opt_args="slow"
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}" do_pkg_build) && eval "${arg_list}" || exit 1

    # set parallel builds or not
    if [[ ! -z ${slow_args+_} ]]; then
	NBUILD_CPUS=1
    else
	NBUILD_CPUS=12
    fi
    
    type do_pkg_build 2>1 1>/dev/null && do_pkg_build "${do_pkg_build_subargs}" || true
    NBUILD_CPUS=1
}

do_make_install() {
    all_opt_args=""
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}" do_pkg_install) && eval "${arg_list}" || exit 1

    rm -rf ${INSTALL_DIR}/*
    
    type do_pkg_install 2>1 1>/dev/null && do_pkg_install "${do_pkg_install_subargs}" || true

    pushd ${INSTALL_DIR}/${PREFIX}
    # Clean up exclude files
    echo "${excludes}" | while read exclude; do
	# rm -rvf $(find . -regextype posix-extended -regex | sed -r 's/..//' | grep -E "${exclude}" | tac)
	if [[ -z "${exclude}" ]]; then
	    echo Warning: Empty exclude field post- package install.;
	else
	    rm -rfv $(find . | sed -r 's/..//' | grep -E "${exclude}" | tac);
	fi
    done
    popd
}

do_package() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1

    # Copy over only the files we want from the filelist
    # rm -rf ${INSTALL_DIR}/files
    # mkdir -p ${INSTALL_DIR}/files
    # rsync -arv --ignore-missing-args --files-from=${FILELIST} ${INSTALL_DIR}${PREFIX} ${INSTALL_DIR}/files
    # MISSING_FILES=$(find ${INSTALL_DIR}/files ! -type d | sort | sed -r "s/^(\/){0,1}([^/]*\/){6}//" | comm -13 - ${FILELIST})
    # if [[ ! -z "${MISSING_FILES}" ]]; then
    # 	echo "Warning: missing files in filelist while packaging" >&2
    # 	echo ${MISSING_FILES} | sed 's/ /\n/g' | sed 's/^/  /'>&2
    # fi

    # Generate install file list
    find ${INSTALL_DIR}${PREFIX} ! -type d | sed "s/$(sedify_string ${INSTALL_DIR}${PREFIX}/)//" | sort > ${FILELIST}

    # Package files
    tar -C ${INSTALL_DIR}${PREFIX} -czvf ${INSTALL_DIR}/${TARBALL} .

    # Move to pkg location
    mv -v ${INSTALL_DIR}/${TARBALL} ${PKG_DIR}/
}

do_install() {
    all_opt_args=
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1

    pushd ${PKG_DIR}

    # Make sure we have something to install
    ([ ! -e ${TARBALL} ] || [ ! -e ${FILELIST} ]) && (echo Nothing to install... && exit 1) || true

    # Make the tmp install dir, unpack and rsync to destination
    rm -rf unpack_${PKG_NAME}
    mkdir unpack_${PKG_NAME}
    tar -C unpack_${PKG_NAME} -xf ${TARBALL}

    mkdir -p ${PREFIX}
    rsync -arv --ignore-missing-args --files-from=${FILELIST} unpack_${PKG_NAME}/ ${PREFIX}
    popd
}

do_all() {
    all_opt_args="setup configure prebuild build minst package install"
    arg_list=$(parse_arg_string \
		   "${1}" \
		   "${all_opt_args}" \
		   "do_setup do_configure do_pre_build do_build do_make_install do_package do_install") \
	&& eval "${arg_list}" || exit 1

    echo here >&2
    exit 0

    # Run 'all' sequence
    do_setup          "${setup_args}"
    do_configure      "${configure_args}"
    do_pre_build      "${prebuild_args}"
    do_build	      "${build_args}"
    do_make_install   "${minst_args}"
    do_package        "${package_args}"
    do_install        "${install_args}"
}

do_clean() {
    # all_opt_args="fast"
    # arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1
    
    cd $(dirname ${BUILD_DIR})
    case ${1} in
	# sysroots
        tools )
	    rm -rfv ${TOOL_SYSROOT}
	    ;;
        target_sysroot )
	    rm -rfv ${TARGET_SYSROOT}
	    ;;
	local_bin )
	    rm -rf ${LOCAL_BUILD_ROOT}
	    ;;
	all_roots )
	    bash ${SCRIPT_PATH} ${PKG_NAME} clean tools
	    bash ${SCRIPT_PATH} ${PKG_NAME} clean target_sysroot
	    bash ${SCRIPT_PATH} ${PKG_NAME} clean local_bin
	    ;;
	# working directories
        build )
	    rm -vrf ${BUILD_DIR}
	    rm -vf ${OVERRIDE_FILE_PATH}
	    ;;
        install )
	    rm -vrf ${INSTALL_DIR}
	    ;;
	workdirs )
	    bash ${SCRIPT_PATH} ${PKG_NAME} clean build
	    bash ${SCRIPT_PATH} ${PKG_NAME} clean install
	    ;;
	# all package specific items
	extract )
	    rm -rfv ${EXTRACT_DIR}
	    ;;
	all_pkg )
	    bash ${SCRIPT_PATH} ${PKG_NAME} clean workdirs
	    bash ${SCRIPT_PATH} ${PKG_NAME} clean extract
	    ;;
	* )
	    echo Unknown clean target ${1}
	    echo "  Targets: 
    tools                    - host tool sysroot
    target_sysroot           - target sysroot
    local_root               - local buildroot in rpmbuild/.buildroot
    all_roots                - all root clean targets
    build                    - build directory and the config override file
    install install_dir      - the build-local install directory
    workdirs build install   - working directories; build and local install
    extract extract_dir      - source extract dir
    all_pkg workdirs extract - all package work dirs and extract dir"
	    ;;
    esac
}

do_manual_make() {
    all_opt_args="dir target vars debug dry fast destdir"
    arg_list=$(parse_arg_string "${1}" "${all_opt_args}") && eval "${arg_list}" || exit 1

    MAKE_FLAGS=
    [ ! -z ${target_args}  ] && MAKE_FLAGS="${MAKE_FLAGS} ${target_args}" \
                             || (echo No target given to manual make && exit 1)
    if [[ ! -z ${dir_args+_} ]]; then
	if [[ -z ${dir_args} ]]; then
	    echo No directory given for dir opt && exit 1
        fi
        MAKE_FLAGS="${MAKE_FLAGS} -C ${dir_args}"
    fi
    [ ! -z ${destdir_args+_} ] && MAKE_FLAGS="${MAKE_FLAGS} DESTDIR=${INSTALL_DIR}"
    [ ! -z ${vars_args}      ] && MAKE_FLAGS="${MAKE_FLAGS} ${vars_args}"
    [ ! -z ${debug_args+_}   ] && MAKE_FLAGS="${MAKE_FLAGS} -d"
    [ ! -z ${dry_args+_}     ] && MAKE_FLAGS="${MAKE_FLAGS} -n"
    [ ! -z ${fast_args+_}    ] && MAKE_FLAGS="${MAKE_FLAGS} -j12"
    
    make ${MAKE_FLAGS}
}

do_manual_call() {
    echo do: ${1}, with: $@
}

####################################################################################################
# Common functions
####################################################################################################
# Convert arg string input <var>=<value>[; <var>=<value>]* variable pairs into
# a string that can be evalled for later use. After evaluation <value> is
# stored in the '<var>_args' variable.
parse_arg_string() {
    user_string=${1}
    opt_string=${2}
    clbks=${3} # also include options for the callbacks

    # Split user_string into var,value pairs
    var_value_regexp=$(echo '^[ ]*([^ ;]+)[ ]*([^" ;]+|"[^"]*"){0,1}[ ]*(;){0,1}(.*)')
    arg_list=""
    while true
    do
	var=$(echo "${user_string}" | sed -r 's/'"${var_value_regexp}"'/\1/')
	value=$(echo "${user_string}" | sed -r 's/'"${var_value_regexp}"'/\2/')
        user_string=$(echo "${user_string}" | sed -r 's/'"${var_value_regexp}"'/\4/')
	[ -z "${var}" ] && break
	arg_list=$(echo "${arg_list}" "${var}" "${value}" | xargs -0 printf "%s%s %s\n")
    done
    arg_list=$(echo "${arg_list}" | sed -r 's/^[ ]*//')

    # Check for the help string
    if [[ ! -z $(echo "${arg_list}" | sed -r 's/^([^ ]+).*/\1/' | grep -E '^help$' && echo yes) ]]; then
	# print args, recursively too on clbk
	echo -e : >&2
	if [[ ! -z ${opt_string} ]]; then
	    echo "  '${opt_string}'" >&2
	fi
	for clbk in ${clbks}; do
	    if [ ! -z "${clbk}" ] && (type ${clbk} 2>1 1>/dev/null); then
		echo -n '  +  '${clbk}>&2
		sub_arg_text=$((eval "${clbk} help") 2>&1 1>/dev/null)
		echo "${sub_arg_text}" | head -n 1 >&2
	        echo "${sub_arg_text}" | tail -n +2 | sed s/^/\ \ \|/ >&2
	    fi
	done
        exit 1
    fi

    # Check for invalid options
    opt_string_sed=$(echo ${opt_string} | sed 's/ /|/g')
    invalid_opts=$(echo "${arg_list}" | sed -r 's/^([^ ]+).*/\1/' \
				      | grep -vE '^>' \
		                      | grep -vE ^\(${opt_string_sed}\)\$) \
                 || true
    [ ! -z "${invalid_opts}" ] && echo Invalid opts \'"${invalid_opts}"\' >&2 && exit 1

    # Convert arg list into an evaluatable var,value string
    eval_arg_string=$(echo "${arg_list}" \
			  | grep -vE '^>' \
     	                  | sed -r 's/^[ ]*([^ ]+)[ ]*($|.*)/\1_args=\2;/')
    # construct arg lists for callbacks too
    sub_arg_string=
    all_subargs=$(echo "${arg_list}" | grep -E '^>' | sed -r 's/^>//')
    for clbk in ${clbks}; do
	this_clbk_subargs=$(echo "${all_subargs}" | grep -E "^${clbk}" | sed -r s/^${clbk},//g | tr '\n' '; ')
	sub_arg_string=$(echo "${clbk}_subargs="\""${this_clbk_subargs}"\")\;"${sub_arg_string}"
    done
    final_eval_string="${eval_arg_string}${sub_arg_string}"
    if [[ ! -z ${final_eval_string} ]]; then
	echo "${final_eval_string}"
    else
	echo :
    fi
}

sedify_string() {
    echo $(echo ${1} | sed 's/\//\\\//g')
}

# ${1} is a string of vars that we want saved
# one <var>=<value>; per line in <pkg>.override file
save_overrides() {
    overrides="${1}"
    
    if [[ -e ${OVERRIDE_FILE_PATH} ]]; then
        saved_overrides=$(cat ${OVERRIDE_FILE_PATH})
    else
	saved_overrides=
    fi

    # extract override variable names to search against
    new_override_vars_grep_string=$(echo ${overrides} | sed 's/ /|/g')

    # remove to-be-updated variable overrides from the current saved overrides
    saved_overrides=$(echo "${saved_overrides}" | grep -vE "^(${new_override_vars_grep_string})")
    # put non-updated overrides back into file
    echo "${saved_overrides}" > ${OVERRIDE_FILE_PATH}

    # construct <var>=<value>; eval strings for each override and put it in the file
    overrides_eval_string=
    for var in ${overrides}; do
	var_value_string="${var}=\"${!var}\";"
        overrides_eval_string=$(echo -e "${var_value_string}\n${overrides_eval_string}")
    done
    echo "${overrides_eval_string}" >> ${OVERRIDE_FILE_PATH}
}

####################################################################################################
# Type functions
####################################################################################################
# Register a <registree>, <clbk> pair on a list of callbacks
# 1: callback list name
# 2: registree name
# 3: callback name
register_clbk() {
    setstr="${1}=\${${1}}"'$(echo -e "\n"'"${2} ${3}"')'
    eval "$setstr"
}
