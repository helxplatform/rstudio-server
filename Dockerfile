## Dockerfile for rocker/tidyverse with trial base-layer security improvements, based on Rstudio tidyverse image with additional upgrades ###
FROM rocker/rstudio:3.5.3
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  libxml2-dev \
  libcairo2-dev \
  libsqlite3-dev \
  libmariadbd-dev \
  libmariadb-client-lgpl-dev \
  unixodbc-dev \
  libssl-dev \
  libssh2-1-dev \
  libpq-dev \
  && install2.r --error \
    --deps TRUE \
    tidyverse \
    dplyr \
    devtools \
    formatR \
    remotes \
    selectr \
    caTools \
    BiocManager
RUN wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz && \
    tar -zxf openssl-1.1.1a.tar.gz && cd openssl-1.1.1a && \
    ./config && \
    apt install make gcc && \
    make && \
    make test && \
    mv /usr/bin/openssl ~/tmp && \
    make install && \
    ln -s /usr/local/bin/openssl /usr/bin/openssl && \
    sudo ldconfig 
RUN groupadd -r -g 1001 user && useradd -r -g user -u 1001 user
WORKDIR /home/user
EXPOSE 8787
USER rstudio
CMD ["/usr/lib/rstudio-server/bin/rserver","--server-daemonize=0","--auth-none=1"]
