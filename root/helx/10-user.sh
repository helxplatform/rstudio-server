#!/bin/bash

set -eoux pipefail

mkdir -p $HOME
# Copy default environment setup files if they don't already exist.
if [ ! -f $HOME/.bashrc ]; then
    cp /etc/skel/.bashrc $HOME/.bashrc
fi
if [ ! -f $HOME/.bash_logout ]; then
    cp /etc/skel/.bash_logout $HOME/.bash_logout
fi
if [ ! -f $HOME/.profile ]; then
    cp /etc/skel/.profile $HOME/.profile
fi
