# A Docker image with all dependencies required to run (not build) an S4TF toolchain.

ARG S4TF_CUDA_VERSION
ARG S4TF_CUDNN_VERSION

FROM nvidia/cuda:${S4TF_CUDA_VERSION}-cudnn${S4TF_CUDNN_VERSION}-devel-ubuntu18.04

# ARGs from before FROM are cleared after the FROM, so we repeat ourselves.
ARG S4TF_CUDA_VERSION
ARG S4TF_CUDNN_VERSION

ENV DEBIAN_FRONTEND=noninteractive

# Install Swift deps.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
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
        python3-dev \
        python3-pip \
        python3-setuptools \
        clang \
        libcurl4-openssl-dev \
        libicu-dev \
        libpython-dev \
        libpython3-dev \
        libncurses5-dev \
        libxml2 \
        libblocksruntime-dev \
        libbsd-dev \
# Install Python libraries
    && pip3 install numpy matplotlib gym psutil junit-xml \
# Configure cuda
    && echo "/usr/local/cuda-${S4TF_CUDA_VERSION}/targets/x86_64-linux/lib/stubs" > /etc/ld.so.conf.d/cuda-${S4TF_CUDA_VERSION}-stubs.conf \
    && ldconfig
