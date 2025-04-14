#!/bin/bash

set -eoux pipefail

# Get directory containing this script.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TIMESTAMP=`date "+%Y%m%d%H%M"`

RSTUDIO_SOURCE_TAG=${RSTUDIO_SOURCE_TAG-"v2024.12.1+563"}
IMAGE=${IMAGE-"focal"}

RSTUDIO_TARBALL="${RSTUDIO_SOURCE_TAG}.tar.gz"
RSTUDIO_TARBALL_URL="https://github.com/rstudio/rstudio/archive/refs/tags/${RSTUDIO_TARBALL}"

cd $SCRIPT_DIR
if [[ ! -f $RSTUDIO_TARBALL ]]
then
  wget $RSTUDIO_TARBALL_URL
fi

RSTUDIO_SRC_DIR_FULL_PATH=$SCRIPT_DIR/rstudio-src
if [[ -d $RSTUDIO_SRC_DIR_FULL_PATH ]]
then
  CALENDAR_VERSION=$(cat $RSTUDIO_SRC_DIR_FULL_PATH/version/CALENDAR_VERSION)
  PATCH=$(cat $RSTUDIO_SRC_DIR_FULL_PATH/version/PATCH)
  echo "
  The $RSTUDIO_SRC_DIR_FULL_PATH directory exists, so assuming it has a valid version of the rstudio source files.  To start with a fresh version of the rstudio source files (if you are building to update the Rstudio source tag version) run 'make clean' and 'make build'.

    current rstudio-src version: v$CALENDAR_VERSION.$PATCH

  Sleeping five seconds...
  "
  sleep 5
else
  echo "creating $RSTUDIO_SRC_DIR_FULL_PATH and extracting rstudio sources"
  mkdir -p $RSTUDIO_SRC_DIR_FULL_PATH
  cd $RSTUDIO_SRC_DIR_FULL_PATH
  tar xf $SCRIPT_DIR/$RSTUDIO_TARBALL --strip-components=1
  cd $SCRIPT_DIR
fi

REPO="localhost/jenkins-rstudio-builder"
IMAGE_TAG="$IMAGE-amd64"

# check to see if there's already a built image
IMAGEID=$(docker images "$REPO:$IMAGE_TAG" --format "{{.ID}}")
if [ -z "$IMAGEID" ]; then
    echo "No image found for $REPO:$IMAGE_TAG."
else
    echo "Found image $IMAGEID for $REPO:$IMAGE_TAG."
fi

cd $RSTUDIO_SRC_DIR_FULL_PATH
docker build                              \
  --tag "$REPO:$IMAGE_TAG"                  \
  --file "docker/jenkins/Dockerfile.$IMAGE" \
  .
