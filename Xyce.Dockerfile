FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Australia/Brisbane
# Use Australian Ubuntu archive, https://gist.github.com/magnetikonline/3a841b5268d5581b4422
# If you're not down under, you will probably want to change this to your local mirror
RUN sed --in-place --regexp-extended "s/(\/\/)(archive\.ubuntu)/\1au.\2/" /etc/apt/sources.list

# Based on: https://github.com/siliconcompiler/siliconcompiler/blob/main/siliconcompiler/toolscripts/ubuntu20/install-xyce.sh
RUN apt update; apt install -y build-essential gcc g++ make cmake automake autoconf bison flex git libblas-dev \
    liblapack-dev liblapack64-dev libfftw3-dev libsuitesparse-dev libopenmpi-dev libboost-all-dev \
    libnetcdf-dev libmatio-dev gfortran libfl-dev libtool python3-venv wget sudo ca-certificates \
    software-properties-common

# CMake
WORKDIR /tmp
RUN wget https://github.com/Kitware/CMake/releases/download/v3.26.4/cmake-3.26.4-linux-x86_64.sh; \
    chmod +x cmake-3.26.4-linux-x86_64.sh; \
    ./cmake-3.26.4-linux-x86_64.sh --skip-license --prefix=/usr/local

# Deps
RUN mkdir -p deps
WORKDIR /deps

# Download Trilinos.
## Version specified in: https://github.com/Xyce/Xyce/blob/master/INSTALL.md#building-trilinos
RUN wget https://github.com/trilinos/Trilinos/archive/refs/tags/trilinos-release-14-4-0.tar.gz --no-verbose \
    -O trilinos.tar.gz; \
    mkdir -p trilinos; \
    tar --strip-components=1 -xf trilinos.tar.gz -C trilinos

# Download Xyce.
WORKDIR /build
RUN git clone --recursive -j8 https://github.com/Xyce/Xyce.git; cd Xyce; git checkout Release-7.10.0

# Build Trilinos
WORKDIR /build/Xyce
RUN mkdir trilinos-build; \
    cd trilinos-build; \
    cmake \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D AMD_LIBRARY_DIRS="/usr/lib" \
        -D TPL_AMD_INCLUDE_DIRS="/usr/include/suitesparse" \
        -C ../cmake/trilinos/trilinos-base.cmake \
        /deps/trilinos; \
    cmake --build . -j$(nproc); \
    sudo make install

# Build Xyce
WORKDIR /build/Xyce
RUN mkdir xyce-build; \
    cd xyce-build; \
    cmake \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D Trilinos_ROOT=/usr/local \
        -D BUILD_SHARED_LIBS=ON \
        ..; \
    cmake --build . -j$(nproc); \
    cmake --build . -j$(nproc) --target xycecinterface; \
    sudo make install
