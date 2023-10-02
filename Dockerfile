FROM ubuntu:jammy-20230816 as base

# Instructions from https://posit.co/download/rstudio-server/.

# Add CRAN package repository for R packages.
RUN apt update -y -qq && \
  apt install -y --no-install-recommends software-properties-common dirmngr wget && \
  wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
  add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# Install R, vim, sudo (for rstudio build). 
RUN apt install -y --no-install-recommends r-base && \
    apt install -y vim sudo

FROM base as builder

# Get rstudio source and extract it.
# See https://github.com/rstudio/rstudio/tags for versions.
ARG RSTUDIO_SOURCE_TAG="v2022.07.2+576"
# ENV RSTUDIO_TARBALL_URL="https://github.com/rstudio/rstudio/tarball/v2022.07.2+576" \
ENV RSTUDIO_TARBALL_URL="https://github.com/rstudio/rstudio/archive/refs/tags/${RSTUDIO_SOURCE_TAG}.tar.gz" \
    TARBALLS_DIR="/usr/local/src/tarballs" \
    RSTUDIO_DEST_TARBALL="rstudio-src.tar.gz" \
    RSTUDIO_SRC_DIR="/usr/local/src/rstudio"
WORKDIR $TARBALLS_DIR
ADD $RSTUDIO_TARBALL_URL $RSTUDIO_DEST_TARBALL
WORKDIR $RSTUDIO_SRC_DIR
RUN tar xf $TARBALLS_DIR/rstudio-src.tar.gz  --strip-components=1

# Install rstudio-server build dependencies.
ENV RSTUDIO_BUILD_DIR="$RSTUDIO_SRC_DIR/build"
WORKDIR $RSTUDIO_SRC_DIR/dependencies/linux
RUN ./install-dependencies-jammy

# Configure, build and install rstudio-server.
WORKDIR $RSTUDIO_BUILD_DIR
RUN cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local/lib/rstudio-server && \
    make install

# Drop build layer and copy the rstudio-server installed files to another
# layer.  This reduces the image size by >5GB.
FROM base as rstudio-server-bin
COPY --from=builder /usr/local/lib/rstudio-server /usr/local/lib/rstudio-server

# Install rstudio-server package dependencies.  Package list taken from
# "Depends" section in output of the dpkg command.
#   dpkg -I rstudio-server-2023.03.0-386-amd64.deb
# URL: https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2023.03.0-386-amd64.deb
RUN apt update -y -qq && \
    apt install -y libc6 libclang-dev libpq5 libsqlite3-0 libssl-dev \
    lsb-release psmisc sudo

# Copy files used for rstudio configuration and starting rstudio-server.
COPY root /

# Create rstudio-server user and modify file/directory permissions.
RUN useradd -u 1000 -g root -r -s /bin/bash -m rstudio && \
    mkdir -p /var/log/rstudio/rstudio-server && \
    chgrp -R 0 /var/log/rstudio/rstudio-server && \
    chmod -R g+rwx /var/log/rstudio/rstudio-server && \
    mkdir -p /var/lib/rstudio-server && \
    chgrp -R 0 /var/lib/rstudio-server && \
    chmod -R g+rwx /var/lib/rstudio-server && \
    mkdir -p /var/run/rstudio-server && \
    chgrp -R 0 /var/run/rstudio-server && \
    chmod 777 /var/run/rstudio-server && \
    chmod +t /var/run/rstudio-server && \
    chmod g+w /etc/passwd && \ 
    chmod 770 /home && \
    chmod 770 /home/rstudio && \
    chgrp -R 0 /etc/rstudio && \
    chmod -R g+rwx /etc/rstudio && \
    ln -s /usr/local/lib/rstudio-server/extras/init.d/debian/rstudio-server /rstudio-server

WORKDIR /
USER rstudio
CMD /start.sh
