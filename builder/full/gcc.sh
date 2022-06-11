#!/bin/bash

[ "$1" = bootstrap ] && bootstrap=yes

DO_SCRIPT=$(readlink -f $(dirname $0)/../do.sh)

bash ${DO_SCRIPT} gcc clean all_pkg
bash ${DO_SCRIPT} gcc setup ">do_pkg_setup,target arm-none-eabi"${bootstrap+";do_pkg_setup,bootstrap"}
bash ${DO_SCRIPT} gcc cfg ""
bash ${DO_SCRIPT} gcc pbld "fast"
bash ${DO_SCRIPT} gcc build ""
bash ${DO_SCRIPT} gcc minst ""
bash ${DO_SCRIPT} gcc pkg ""
# bash ${DO_SCRIPT} newlib install ""
