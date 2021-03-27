#!/usr/bin/env bash
CWD="$(pwd -P)"

sudo -H dnf -y install gcc libX11-devel freetype-devel zlib-devel libxcb-devel libxslt-devel libgcrypt-devel libxml2-devel gnutls-devel libpng-devel libjpeg-turbo-devel libtiff-devel dbus-devel fontconfig-devel

mkdir -pv ./downloads
wget https://dl.winehq.org/wine/source/6.x/wine-6.5.tar.xz -O ./downloads/wine-6.5.tar.xz

if [ ! -d "$CWD/src" ]; then
    mkdir -pv ./src
fi
tar xvf ./downloads/wine-6.5.tar.xz -C ./src/
WINE_SRC_DIR="$CWD/src/wine-6.5"

WINE_BUILD_DIR="$CWD/build/wine-6.5-build"
if [ ! -d "$CWD/build" ]; then
    mkdir -pv "$CWD/build"
fi
mkdir -pv "$WINE_BUILD_DIR"

CC="gcc" CXX="g++" CFLAGS="-O3 -march=native -fomit-frame-pointer -pipe" CXXFLAGS="-O3 -march=native -fomit-frame-pointer -pipe" LDFLAGS="-Wl,-rpath=$HOME/.local/lib -Wl,-rpath=$HOME/.local/lib64" cd "$WINE_BUILD_DIR" && "$WINE_SRC_DIR/configure" \
	--prefix="$HOME/.local" \
	--enable-win64 && cd "$CWD"

cd "$WINE_BUILD_DIR" && make -j 4 && make install
cd "$CWD"

rm -rf ./download ./src ./build
