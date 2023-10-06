#!/bin/bash

if [ "$BASE_PATH" != "" ]; then
  echo "www-root-path=$BASE_PATH/">>/etc/rstudio/rserver.conf
fi

# Modify username that rstudio-server runs as.
cp /etc/rstudio/rserver.conf /tmp/rserver.conf
sed -i -e "s/^server-user=rstudio/server-user=$USER/" /tmp/rserver.conf
cp /tmp/rserver.conf /etc/rstudio/rserver.conf
rm /tmp/rserver.conf

/rstudio-server start
