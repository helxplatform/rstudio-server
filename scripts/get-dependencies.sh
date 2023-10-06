#!/bin/bash

PACKAGE_TO_CHECK=${1-"/local/rstudio/docker/package/rstudio-server-202310041813.10.999--amd64-relwithdebinfo.deb"}

PACKAGES=$( dpkg -I $PACKAGE_TO_CHECK | grep "^ Depends: " )

for PACKAGE in $PACKAGES
  do
    if [[ $PACKAGE != "Depends:" ]]
    then
      # Remove items with '(' or ')', they are versions.
      if [[ ! $( echo $PACKAGE | grep -e "(" -e ")" ) ]]
      then
        PACKAGES_TO_INSTALL+="$( echo $PACKAGE | tr -d ',' ) "
      fi
    fi
  done
echo $PACKAGES_TO_INSTALL
