#!/bin/bash

[ "$1" = bootstrap ] && bootstrap=yes

DO_SCRIPT=$(readlink -f $(dirname $0)/../do.sh)

bash ${DO_SCRIPT} newlib clean all_pkg
bash ${DO_SCRIPT} newlib setup ">do_pkg_setup,target arm-none-eabi"${bootstrap+";do_pkg_setup,bootstrap"}
bash ${DO_SCRIPT} newlib cfg ""
bash ${DO_SCRIPT} newlib pbld "fast"
bash ${DO_SCRIPT} newlib build ""
bash ${DO_SCRIPT} newlib minst ""
bash ${DO_SCRIPT} newlib pkg ""
# bash ${DO_SCRIPT} newlib install ""
