#!/bin/bash

/home/builder/rpmbuild/BUILDROOT/root/bin/arm-none-eabi-readelf -sW ${1} | grep -vP "([ ]+[^ ]+){3}[ ]+(SECTION|FILE|NOTYPE([ ]+[^ ]+){2}[ ]+"'(?!UND)[^ ]+)'
