# The "rstudio:jammy-amd64-builder" image is built with the create-builder-image.sh script.
FROM rstudio:jammy-amd64-builder as builder

# Install a nodejs version that is newer than the one included in LTS version of Ubuntu.
# https://github.com/nodesource/distributions
RUN apt-get update && apt-get install -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install nodejs -y

ENV RSTUDIO_SRC_DIR="/usr/local/src/rstudio"
COPY rstudio-src $RSTUDIO_SRC_DIR

ENV RSTUDIO_BUILD_DIR="$RSTUDIO_SRC_DIR/build"
WORKDIR $RSTUDIO_BUILD_DIR
RUN cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local/lib/rstudio-server && \
    make install

# Drop build layer and copy the rstudio-server installed files to another
# layer.
FROM ubuntu:jammy-20230816 as base
COPY --from=builder /usr/local/lib/rstudio-server /usr/local/lib/rstudio-server

ARG END_USER_USERNAME=helx
ARG END_USER_ID=1000
ARG END_USER_GROUP_ID=0

# Instructions from https://posit.co/download/rstudio-server/.

# Add CRAN package repository for R packages.
RUN apt-get update && \
  apt-get install -y --no-install-recommends software-properties-common dirmngr wget && \
  wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
  add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# Upgrade packages. Install R, vim, sudo (for rstudio build). 
RUN apt-get upgrade -y && \
    apt-get install -y --no-install-recommends r-base && \
    apt-get install -y vim sudo

# Install rstudio-server package dependencies.  Package list taken from
# "Depends" section in output of the dpkg command.
#   dpkg -I rstudio-server-2023.03.0-386-amd64.deb
# Can use the next few commands to get the dependencies.
# DEB_FILE=rstudio-server-2023.03.0-386-amd64.deb
# DEB_URL="https://download2.rstudio.org/server/jammy/amd64/$DEB_FILE"
# wget $DEB_URL
# docker run --rm -it -v ".:/local" rstudio:jammy-amd64 /local/scripts/get-dependencies.sh /local/$DEB_FILE
RUN apt-get install -y libc6 libclang-dev libpq5 libsqlite3-0 libssl-dev \
    lsb-release psmisc sudo

# Copy files used for rstudio configuration and starting rstudio-server.
COPY root /

# Create rstudio-server user and modify file/directory permissions.
RUN useradd --uid $END_USER_ID --gid $END_USER_GROUP_ID -m $END_USER_USERNAME \
            -s /bin/bash && \
    mkdir -p /var/log/rstudio/rstudio-server && \
    chgrp -R $END_USER_GROUP_ID /var/log/rstudio/rstudio-server && \
    chmod -R g+rwx /var/log/rstudio/rstudio-server && \
    mkdir -p /var/lib/rstudio-server && \
    chgrp -R $END_USER_GROUP_ID /var/lib/rstudio-server && \
    chmod -R g+rwx /var/lib/rstudio-server && \
    mkdir -p /var/run/rstudio-server && \
    chgrp -R $END_USER_GROUP_ID /var/run/rstudio-server && \
    chmod 777 /var/run/rstudio-server && \
    chmod +t /var/run/rstudio-server && \
    chmod g+w /etc/passwd && \
    chmod 770 /home && \
    chmod 770 /home/$END_USER_USERNAME && \
    chgrp -R $END_USER_GROUP_ID /etc/rstudio && \
    chmod -R g+rwx /etc/rstudio && \
    ln -s /usr/local/lib/rstudio-server/extras/init.d/debian/rstudio-server /rstudio-server

WORKDIR /
USER $END_USER_USERNAME
CMD /start.sh
