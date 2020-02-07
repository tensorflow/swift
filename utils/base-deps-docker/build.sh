#!/bin/bash

# Builds base deps docker images for various CUDA versions, and uploads them to
# the Google Container Registry.

set -exuo pipefail

do_build() {
  export S4TF_CUDA_VERSION="$1"
  export S4TF_CUDNN_VERSION="$2"
  IMAGE_NAME="gcr.io/swift-tensorflow/base-deps-cuda${S4TF_CUDA_VERSION}-cudnn${S4TF_CUDNN_VERSION}-ubuntu18.04"
  sudo -E docker build \
    -t "$IMAGE_NAME" \
    --build-arg S4TF_CUDA_VERSION \
    --build-arg S4TF_CUDNN_VERSION \
    .
  docker push "$IMAGE_NAME"
}

do_build 9.2 7
do_build 10.0 7
do_build 10.1 7
