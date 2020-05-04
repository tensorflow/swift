#!/bin/bash

# Installs a Swift for TensorFlow toolchain from scratch on Ubuntu 18.04.
#
# Usage:
#   ./install-ubuntu1804
#     [--toolchain-url TOOLCHAIN_URL]
#     [--jupyter-url JUPYTER_URL]
#     [--cuda CUDA_VERSION]
#     [--no-jupyter]
#     [--install-location INSTALL_LOCATION]
#
# Arguments:
#   --toolchain-url: Specifies the URL for the toolchain. Defaults to the latest
#                    nightly CPU-only toolchain.
#   --jupyter-url: Specifies the URL for swift-jupyter. Defaults to the latest
#                  nightly build. Set this to the empty string to disable
#                  swift-jupyter installation.
#   --install-location: Directory to extract the toolchain. Defaults to
#                       "./swift-toolchain".

set -exuo pipefail

TOOLCHAIN_URL=https://storage.googleapis.com/swift-tensorflow-artifacts/nightlies/latest/swift-tensorflow-DEVELOPMENT-ubuntu18.04.tar.gz
JUPYTER_URL=https://storage.googleapis.com/swift-tensorflow-artifacts/nightlies/latest/swift-jupyter.tar.gz
INSTALL_LOCATION=./swift-toolchain

# Parse arguments.
PARSE_ERROR="invalid arguments"
while
        arg="${1-}"
        case "$arg" in
        --toolchain-url)    TOOLCHAIN_URL="${2?"$PARSE_ERROR"}"; shift;;
        --jupyter-url)      JUPYTER_URL="${2?"$PARSE_ERROR"}"; shift;;
        --install-location) INSTALL_LOCATION="${2?"$PARSE_ERROR"}"; shift;;
        "")                 break;;
        *)                  echo "$PARSE_ERROR" >&2; exit 2;;
        esac
do
        shift
done

# Wait for apt lock to be released
# Source: https://askubuntu.com/a/373478
while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
   sleep 1
done

# Install dependencies
DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  git \
  python \
  python-dev \
  python-pip \
  python-setuptools \
  python-tk \
  python3 \
  python3-pip \
  python3-setuptools \
  clang \
  libcurl4-openssl-dev \
  libicu-dev \
  libpython-dev \
  libpython3-dev \
  libncurses5-dev \
  libxml2 \
  libblocksruntime-dev

# Download and extract Swift toolchain.
mkdir -p "$INSTALL_LOCATION"
wget "$TOOLCHAIN_URL" -O "$INSTALL_LOCATION"/swift-toolchain.tar.gz
tar -xf "$INSTALL_LOCATION"/swift-toolchain.tar.gz -C "$INSTALL_LOCATION"
rm "$INSTALL_LOCATION"/swift-toolchain.tar.gz

# Download, extract, and register Jupyter, if requested.
if [[ ! -z "$JUPYTER_URL" ]]; then
  wget "$JUPYTER_URL" -O "$INSTALL_LOCATION"/swift-jupyter.tar.gz
  tar -xf "$INSTALL_LOCATION"/swift-jupyter.tar.gz -C "$INSTALL_LOCATION"
  rm "$INSTALL_LOCATION"/swift-jupyter.tar.gz

  python3 -m pip install -r "$INSTALL_LOCATION"/swift-jupyter/requirements.txt

  python3 "$INSTALL_LOCATION"/swift-jupyter/register.py --user --swift-toolchain "$INSTALL_LOCATION" --swift-python-library /usr/lib/x86_64-linux-gnu/libpython3.6m.so
fi
