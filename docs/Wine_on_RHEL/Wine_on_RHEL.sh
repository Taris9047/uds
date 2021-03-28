#!/usr/bin/env bash -e
CWD="$(pwd -P)"
if [ ! -d "$CWD/workspace" ]; then
	mkdir -pv "$CWD/workspace"
fi
WORKSPACE="$CWD/workspace"

sudo -H dnf -y install libxslt-devel libpng-devel \
	libX11-devel zlib-devel \
	libtiff-devel freetype-devel libxcb-devel libxml2-devel libgcrypt-devel \
	dbus-devel libjpeg-turbo-devel fontconfig-devel gnutls-devel \
	gstreamer1-devel libXcursor-devel libXi-devel libXrandr-devel \
	libXfixes-devel libXinerama-devel libXcomposite-devel \
	mesa-libOSMesa-devel libpcap-devel libusb-devel \
	libv4l-devel libgphoto2-devel gstreamer1-devel \
	libgudev SDL2-devel gsm-devel libvkd3d-devel libudev-devel \
	libgcc.i686 glibc-devel.i686 dbus-devel.i686 \
	freetype-devel.i686 pulseaudio-libs-devel.i686 \
	libX11-devel.i686 mesa-libGLU-devel.i686 libICE-devel.i686 libXext-devel.i686 libXcursor-devel.i686 libXi-devel.i686 libXxf86vm-devel.i686 libXrender-devel.i686 libXinerama-devel.i686 libXcomposite-devel.i686 libXrandr-devel.i686 mesa-libGL-devel.i686 mesa-libOSMesa-devel.i686 libxml2-devel.i686 libxslt-devel.i686 zlib-devel.i686 gnutls-devel.i686 ncurses-devel.i686 sane-backends-devel.i686 libv4l-devel.i686 libgphoto2-devel.i686 libexif-devel.i686 lcms2-devel.i686 gettext-devel.i686 isdn4k-utils-devel.i686 cups-devel.i686 fontconfig-devel.i686 gsm-devel.i686 libjpeg-turbo-devel.i686 pkgconfig.i686 libtiff-devel.i686 unixODBC.i686 openldap-devel.i686 alsa-lib-devel.i686 audiofile-devel.i686 freeglut-devel.i686 giflib-devel.i686 gstreamer1-devel.i686 gstreamer1-plugins-base-devel.i686 libXmu-devel.i686 libXxf86dga-devel.i686 libieee1284-devel.i686 libpng-devel.i686 librsvg2-devel.i686 libstdc++-devel.i686 libusb-devel.i686 unixODBC-devel.i68

DOWNLOADS="$WORKSPACE/downloads"
if [ ! -d "$DOWNLOADS" ]; then
	mkdir -pv "$DOWNLOADS"
fi
wget https://dl.winehq.org/wine/source/6.x/wine-6.2.tar.xz -O "$DOWNLOADS/wine-6.2.tar.xz"

if [ ! -d "$WORKSPACE/src" ]; then
	mkdir -pv "$WORKSPACE/src"
fi
tar xf "$DOWNLOADS/wine-6.2.tar.xz" -C "$WORKSPACE/src/"
WINE_SRC_DIR="$CWD/workspace/src/wine-6.2"

WINE_BUILD_DIR="$WORKSPACE/build/wine-6.2-build"
if [ ! -d "$WORKSPACE/build" ]; then
	mkdir -pv "$WORKSPACE/build"
fi
mkdir -pv "$WINE_BUILD_DIR"

cd "$WINE_BUILD_DIR" && CC="/usr/bin/gcc" CXX="/usr/bin/g++" CFLAGS="-O3 -march=native -fomit-frame-pointer -pipe" CXXFLAGS="-O3 -march=native -fomit-frame-pointer -pipe" LDFLAGS="-Wl,-rpath=$HOME/.local/lib -Wl,-rpath=$HOME/.local/lib64" "$WINE_SRC_DIR/configure" \
	--prefix="$HOME/.local" && cd "$CWD"

cd "$WINE_BUILD_DIR" && make -j 4 && make install
cd "$CWD"

wget https://dl.winehq.org/wine/wine-mono/6.0.0/wine-mono-6.0.0-x86.msi -O "$DOWNLOADS/wine-mono-6.0.0-x86.msi"
wine msiexec /i $DOWNLOADS/wine-mono-6.0.0-x86.msi

wget http://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86.msi -O "$DOWNLOADS/wine-gecko-2.47.2-x86.msi"
wine msiexec /i $DOWNLOADS/wine-gecko-2.47.2-x86.msi
wget http://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86_64.msi -O "$DOWNLOADS/wine-gecko-2.47.2-x86_64.msi"
wine msiexec /i $DOWNLOADS/wine-gecko-2.47.2-x86_64.msi

rm -rf "$WORKSPACE"
