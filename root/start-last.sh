#!/bin/bash

# UNCDSR-182: /etc/rstudio is now a (fresh, empty) emptyDir mount so the
# container's root filesystem can be read-only. Re-seed it from the
# pristine, never-mounted-over copy baked at /etc/rstudio-defaults before
# mutating it below -- every boot already needed a writable rserver.conf to
# stamp the real username into, this just makes the "writable" part explicit
# instead of relying on the root filesystem being writable everywhere.
# Plain -r, not -a: the destination is an existing emptyDir mount point we
# don't own, so attempting to preserve its own directory metadata (as -a's
# --preserve=all would) fails with a harmless-looking but noisy warning.
# We only need the file contents, not timestamps/ownership on top of them.
cp -r /etc/rstudio-defaults/. /etc/rstudio/

# Modify username that rstudio-server runs as.
cp /etc/rstudio/rserver.conf /tmp/rserver.conf
sed -i -e "s/^server-user=rstudio/server-user=$USER/" /tmp/rserver.conf
if [ "$RSTUDIO_SERVER_BASE_PATH" != "" ]; then
  # Remove any existing lines for www-root-path (usually will not be there).
  # Rstudio will assume the root path '/' if not defined.
  sed -i -e "s/^www-root-path.*//" /tmp/rserver.conf
  # Add line to the end of rserver.conf.
  echo "www-root-path=$RSTUDIO_SERVER_BASE_PATH/">>/tmp/rserver.conf
fi
# Remove any existing lines for log-level (usually will not be there).
sed -i -e "s/^log-level.*//" /tmp/rserver.conf
echo "log-level=${RSTUDIO_LOG_LEVEL}">>/etc/rstudio/logging.conf
cp /tmp/rserver.conf /etc/rstudio/rserver.conf
rm /tmp/rserver.conf

/rstudio-server start
