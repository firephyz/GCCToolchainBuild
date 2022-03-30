#!/bin/bash

bash scripts/builder/do.sh binutils install
bash scripts/builder/do.sh gcc clean all_pkg
bash scripts/builder/do.sh gcc setup ">do_pkg_setup,support_libs; >do_pkg_setup,target arm-none-eabi; >do_pkg_setup,bootstrap"
bash scripts/builder/do.sh gcc cfg
bash scripts/builder/do.sh gcc pbld "fast"
bash scripts/builder/do.sh gcc build
bash scripts/builder/do.sh gcc minst
bash scripts/builder/do.sh gcc pkg
bash scripts/builder/do.sh gcc install

bash scripts/builder/do.sh libgcc clean all_pkg
bash scripts/builder/do.sh gcc setup ">do_pkg_setup,support_libs; >do_pkg_setup,target arm-none-eabi; >do_pkg_setup,bootstrap"
bash scripts/builder/do.sh libgcc setup '>do_pkg_setup,restore'
bash scripts/builder/do.sh libgcc cfg
bash scripts/builder/do.sh libgcc pbld 'fast'
bash scripts/builder/do.sh libgcc build
bash scripts/builder/do.sh libgcc minst
bash scripts/builder/do.sh libgcc pkg
bash scripts/builder/do.sh libgcc install

# bash scripts/builder/do.sh newlib clean all_pkg
# bash scripts/builder/do.sh newlib setup help
# bash scripts/builder/do.sh newlib setup '>do_pkg_setup,bootstrap; >do_pkg_setup,target arm-none-eabi'
# bash scripts/builder/do.sh newlib clean extract
# bash scripts/builder/do.sh newlib setup '>do_pkg_setup,bootstrap; >do_pkg_setup,target arm-none-eabi'
# bash scripts/builder/do.sh newlib cfg help
# bash scripts/builder/do.sh newlib cfg
# bash scripts/builder/do.sh newlib pbld
