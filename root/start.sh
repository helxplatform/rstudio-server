#!/bin/bash

set -eoux pipefail

# UNCDSR-182: /etc/passwd is mounted via subPath on an emptyDir so the
# container's root filesystem can be read-only, which means it starts out
# empty on every boot. Re-seed it from the pristine, never-mounted-over copy
# baked at /etc/passwd.default before anything below (10-user.sh in
# particular) tries to read or rewrite a user entry in it.
if [ ! -s /etc/passwd ]; then
  cp /etc/passwd.default /etc/passwd
fi

export USER=${USER-"helx"}
export USER_UID=${USER_UID-"1000"}
export USER_GID=${USER_GID-"0"}
export DEFAULT_USER="helx"
# WARNING: Setting RSTUDIO_SERVER_BASE_PATH to anything else other than "/"
# will probably not work because of rstudio-server redirects to "/auth-sign-in".
export RSTUDIO_SERVER_BASE_PATH=${RSTUDIO_SERVER_BASE_PATH-"/"}
export RSTUDIO_LOG_LEVEL=${RSTUDIO_LOG_LEVEL-"warn"}
export USER_IDENTITY=${USER_IDENTITY-"local"}

declare -i CURRENT_UID=`id -u`
if [ $CURRENT_UID -ne 0 ]
then
  export HOME="/home/$USER"
else
  export HOME="/root"
fi

# Change to the root directory to mitigate problems if the current working
# directory is deleted.
cd /

# Add other init scripts in $HELX_SCRIPTS_DIR with ".sh" as their extension.
# To run in a certain order, name them appropriately.
HELX_SCRIPT_DIR=/helx
INIT_SCRIPTS_TO_RUN=$(ls -1 $HELX_SCRIPT_DIR/*.sh) || true
for INIT_SCRIPT in $INIT_SCRIPTS_TO_RUN
do
  echo "Running $INIT_SCRIPT"
  $INIT_SCRIPT
done

# Change CWD to /home/$USER so it is the starting point for shells.
cd $HOME

# Where user-specific non-essential (cached) data should be written (analogous to /var/cache).
# Should default to $HOME/.cache.
# https://wiki.archlinux.org/title/XDG_Base_Directory
export XDG_CACHE_HOME=$HOME/.cache

FINAL_COMMAND=${FINAL_COMMAND-"/start-last.sh"}
$FINAL_COMMAND
