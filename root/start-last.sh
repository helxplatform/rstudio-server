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
# UNCDSR-182: rserver requires its server-data-dir to be writable by all
# users with the sticky bit set (mode 1777), and exits if it can't make it
# so. Under a read-only root filesystem /var/run/rstudio-server is an
# emptyDir mount, which Kubernetes creates root-owned with mode 0777 and no
# sticky bit; this process runs as the user, can't chmod a directory it
# doesn't own, and rserver fails with "Operation not permitted". So use a
# subdirectory of that volume that this process creates, owns, and can set
# to 1777 itself. This works the same with a writable root filesystem.
SERVER_DATA_DIR=/var/run/rstudio-server/data
mkdir -p "$SERVER_DATA_DIR"
chmod 1777 "$SERVER_DATA_DIR"
sed -i -e "s/^server-data-dir.*//" /tmp/rserver.conf
echo "server-data-dir=${SERVER_DATA_DIR}">>/tmp/rserver.conf
cp /tmp/rserver.conf /etc/rstudio/rserver.conf
rm /tmp/rserver.conf

# Users reach rserver only through nginx, so do not start rserver without it.
mkdir -p /tmp/nginx
nginx -c /etc/nginx/rstudio/nginx.conf || exit 1

/rstudio-server start
