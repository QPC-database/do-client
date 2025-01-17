#! /bin/bash

# bootstrap scripts will exit immediately if a command exits with a non-zero status
set -e

echo "Setting up development environment for do-client"

# Various development machine tools
apt-get update
apt-get install -y build-essential g++ gdb gdbserver git wget
apt-get install -y python3 cmake ninja-build rpm

# Open-source library dependencies
# Boost libs for DO
apt-get install -y libboost-system-dev libboost-log-dev libboost-filesystem-dev libboost-program-options-dev
# Additional Boost libs for cpprestsdk
apt-get install -y libboost-random-dev libboost-regex-dev
apt-get install -y libgtest-dev libproxy-dev libmsgsl-dev libssl-dev uuid-dev

# Install cpprest dependencies
# libssl-dev also required but installed above because plugin uses libssl-dev directly
apt-get install -y zlib1g-dev

# Cpprestsdk 2.10.15 is the latest publicly available version on Ubuntu 20.04
# Build and install v2.10.16 as it's the earliest version which supports url-redirection
mkdir /tmp/cpprestsdk
cd /tmp/cpprestsdk
git clone https://github.com/microsoft/cpprestsdk.git .
git checkout tags/v2.10.16
git submodule update --init
mkdir /tmp/cpprestsdk/build
cd /tmp/cpprestsdk/build
cmake -G Ninja -DCMAKE_BUILD_TYPE=minsizerel -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DBUILD_SAMPLES=OFF -Wno-dev -DWERROR=OFF ..
ninja
ninja install

# The latest native-version of gtest on Ubuntu20.04 currently has a bug where CMakeLists doesn't declare an install target, causing 'make install' to fail
# Clone from source and use release-1.10.0 instead, since gtest is a source package anyways
mkdir /tmp/gtest
cd /tmp/gtest
git clone https://github.com/google/googletest.git .
git checkout release-1.10.0
mkdir cmake
cd cmake
cmake /tmp/gtest
make
make install

if [[ "$1" == "--no-tools" ]]; then
  echo "Skipping tools install"
else
  apt install -y python-pip
  pip install cpplint
  # Installs to a non-standard location so add to PATH manually
  export PATH=$PATH:~/.local/bin

  # Install docker to enable building cross-arch for arm
  # Instructions located at: https://docs.docker.com/engine/install/ubuntu/
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  # Install qemu for cross-arch support
  apt-get -y install qemu binfmt-support qemu-user-static

  # Register qemu with docker to more easily run cross-arch containers
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
fi

echo "Finished bootstrapping"
