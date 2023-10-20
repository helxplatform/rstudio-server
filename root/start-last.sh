#!/bin/bash

if [ "$BASE_PATH" != "" ]; then
  echo "www-root-path=$BASE_PATH/">>/etc/rstudio/rserver.conf
fi

# Modify username that rstudio-server runs as.
cp /etc/rstudio/rserver.conf /tmp/rserver.conf
sed -i -e "s/^server-user=rstudio/server-user=$USER/" /tmp/rserver.conf
if [ "$BASE_PATH" != "" ]; then
  # Remove any existing lines for www-root-path (usually will not be there).
  # Rstudio will assume the root path '/' if not defined.
  sed -i -e "s/^www-root-path.*//" /tmp/rserver.conf
  # Add line to the end of rserver.conf.
  echo "www-root-path=$BASE_PATH/">>/tmp/rserver.conf
fi
# Remove any existing lines for log-level (usually will not be there).
sed -i -e "s/^log-level.*//" /tmp/rserver.conf
echo "log-level=${RSTUDIO_LOG_LEVEL}">>/etc/rstudio/logging.conf
cp /tmp/rserver.conf /etc/rstudio/rserver.conf
rm /tmp/rserver.conf

/rstudio-server start
