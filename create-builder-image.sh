#!/bin/bash

set -eoux pipefail

# Get directory containing this script.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TIMESTAMP=`date "+%Y%m%d%H%M"`

RSTUDIO_SOURCE_TAG=${RSTUDIO_SOURCE_TAG-"v2024.12.0+467"}
RSTUDIO_TARBALL="${RSTUDIO_SOURCE_TAG}.tar.gz"
RSTUDIO_TARBALL_URL="https://github.com/rstudio/rstudio/archive/refs/tags/${RSTUDIO_TARBALL}"

cd $SCRIPT_DIR
if [[ ! -f $RSTUDIO_TARBALL ]]
then
  wget $RSTUDIO_TARBALL_URL
fi

RSTUDIO_SRC_DIR=$SCRIPT_DIR/rstudio-src
if [[ -d $RSTUDIO_SRC_DIR ]]
then
  echo "$RSTUDIO_SRC_DIR exists, so assuming it already has the rstudio sources"
else
  echo "creating $RSTUDIO_SRC_DIR and extracting rstudio sources"
  mkdir -p $RSTUDIO_SRC_DIR
  cd $RSTUDIO_SRC_DIR
  tar xf $SCRIPT_DIR/$RSTUDIO_TARBALL --strip-components=1
  cd $SCRIPT_DIR
fi

REPO="localhost/rstudio"
IMAGE_TAG="jammy-amd64-builder"

# check to see if there's already a built image
IMAGEID=$(docker images "$REPO:$IMAGE_TAG" --format "{{.ID}}")
if [ -z "$IMAGEID" ]; then
    echo "No image found for $REPO:$IMAGE_TAG."
else
    echo "Found image $IMAGEID for $REPO:$IMAGE_TAG."
fi

cd $RSTUDIO_SRC_DIR
IMAGE=jammy
docker build                                \
  --tag "$REPO:$IMAGE_TAG"                  \
  --file "docker/jenkins/Dockerfile.$IMAGE" \
  .
