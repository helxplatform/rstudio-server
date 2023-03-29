#!/bin/bash

# Use variables already available from Tycho if there.
if [ -z "${NB_USER+x}" ]; then
  echo "NB_USER is not set"
else
  echo "setting USER=$NB_USER"
  USER=$NB_USER
fi
if [ -z "${NB_PREFIX+x}" ]; then
  echo "NB_PREFIX is not set"
else
  echo "setting RSTUDIO_PREFIX=$NB_PREFIX"
  RSTUDIO_PREFIX=$NB_PREFIX
fi

USER=${USER-"rstudio"}
MOVE_RSTUDIO_SERVER_HOME=${MOVE_RSTUDIO_SERVER_HOME-"yes"}
DELETE_RSTUDIO_SERVER_HOME_IF_UNUSED=${DELETE_RSTUDIO_SERVER_HOME_IF_UNUSED-"yes"}
RSTUDIO_USER="rstudio"
# RSTUDIO_SERVER_INIT="/usr/local/lib/rstudio-server/extras/init.d/debian/rstudio-server"
# RSTUDIO_SERVER_INIT="/etc/init.d/rstudio-server"
RSTUDIO_SERVER_INIT="/rstudio-server"

echo "before /etc/passwd modifications"
echo "id: `id`"
echo "USER: $USER"
echo ""

if [ `id -u` -ne 0 ]; then
  echo "not running as root"
  if [[ `id -u` -ne 1000 || "$USER" != "$RSTUDIO_USER" ]]; then
    echo "not running as uid=1000 or USER!=\"$RSTUDIO_USER\""
    # Modify user entry in /etc/passwd.
    cp /etc/passwd /tmp/passwd
    sed -i -e "s/^$RSTUDIO_USER\:x\:1000\:0\:\:\/home\/$RSTUDIO_USER/$USER\:x\:`id -u`\:`id -g`\:\:\/home\/$USER/" /tmp/passwd
    cp /tmp/passwd /etc/passwd
    rm /tmp/passwd

    echo "after /etc/passwd modifications"
    echo "id: `id`"
    echo "USER: $USER"
    echo ""

    # Modify username that rstudio-server runs as.
    cp /etc/rstudio/rserver.conf /tmp/rserver.conf
    sed -i -e "s/^server-user=$RSTUDIO_USER/server-user=$USER/" /tmp/rserver.conf
    cp /tmp/rserver.conf /etc/rstudio/rserver.conf
    rm /tmp/rserver.conf

    # Might not want to move the rstudio-server home folder to $USER,
    # rstudio-server will create a home directory for the user it is
    # running as if it doesn't exist.
    if [[ "$MOVE_RSTUDIO_SERVER_HOME" == "yes" ]]; then
      mv /home/$RSTUDIO_USER /home/$USER
    fi

    if [[ -d /home/$RSTUDIO_USER ]]; then
      if [[ "$USER" != "$RSTUDIO_USER" && "$DELETE_RSTUDIO_SERVER_HOME_IF_UNUSED" == "yes" ]]; then
        rm -rf /home/$RSTUDIO_USER
      fi
    fi

  else
    echo "running as uid=1000 and USER=\"$RSTUDIO_USER\""
  fi
fi

# The USER environment variable needs to be set for rserver.
export USER

if [ "$RSTUDIO_PREFIX" != "" ]; then
  echo "www-root-path=$RSTUDIO_PREFIX/">>/etc/rstudio/rserver.conf
fi

$RSTUDIO_SERVER_INIT start
