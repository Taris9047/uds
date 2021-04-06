#!/usr/bin/env bash -e
CWD="$(pwd -P)"
if [ ! -d "${CWD}/workspace" ]; then
	mkdir -pv "${CWD}/workspace"
fi
WORKSPACE="${CWD}/workspace"
WINE_VER="6.0"
WINE_VER_MAJOR=$(echo ${WINE_VER} | cut -d'.' -f1)
WINE_VER_URL=$(echo ${WINE_VER} | cut -d'.' -f1,2)

log="$(mktemp -t install-wine.XXXXXX.log)"

# Checking for wget
if [ ! -x "$(command -v wget)" ]; then
	echo "Oops! wget is a must!!"
	exit 1
fi

compile_only="false"
# if [ $# -ne 0 ]; then
#     if [ "$1" = "compile_only" ]; then
#         compile_only="true"
#     fi
# fi
usage () {
    echo ""
    echo "Options are: compile_only"
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`

    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        compile_only)
            compile_only="true"
            ;;
        *)
            echo "Error! Unknown Parameter!!"
            usage
            exit 1
            ;;
    esac
    shift
done

if [ "$compile_only" = "false" ]; then
    echo "Installing prerequisite packages..."

    sudo -H dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y 2>&1 >>$log
    sudo -H subscription-manager repos --enable "codeready-builder-for-rhel-8-x86_64-rpms"
    # sudo -H dnf config-manager --set-enable PowerTools 2>&1 >>$log # CentOS8

    sudo -H rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro 2>&1 >>$log
    sudo -H dnf install http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm -y 2>&1 >>$log
    sudo -H dnf clean all 2>&1 >>$log
    sudo -H dnf update --best --allowerasing -y 2>&1 >>$log

    echo "Removing wine from official repo."
    sudo -H dnf remove wine wine-* -y 2>&1 >>$log

    sudo -H dnf install libjpeg-turbo-devel libtiff-devel freetype-devel -y 2>&1 >>$log
    sudo -H dnf install glibc-devel.{i686,x86_64} libgcc.{i686,x86_64} libX11-devel.{i686,x86_64} freetype-devel.{i686,x86_64} gnutls-devel.{i686,x86_64} libxml2-devel.{i686,x86_64} libjpeg-turbo-devel.{i686,x86_64} libpng-devel.{i686,x86_64} libXrender-devel.{i686,x86_64} alsa-lib-devel.{i686,x86_64} glib2-devel.{i686,x86_64} libSM-devel.{i686,x86_64} -y 2>&1 >>$log
fi

if [ "$compile_only" = "false" ]; then
    echo "Installing some edge case 32bit packages..."
    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/prelink-0.5.0-9.el7.x86_64.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/isdn4k-utils-3.2-99.el7.x86_64.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/isdn4k-utils-devel-3.2-99.el7.x86_64.rpm -y 2>&1 >>$log
    sudo -H dnf install glibc-devel libstdc++-devel icoutils openal-soft-devel prelink gstreamer1-plugins-base-devel gstreamer1-devel ImageMagick-devel fontpackages-devel libv4l-devel gsm-devel giflib-devel libXxf86dga-devel mesa-libOSMesa-devel isdn4k-utils-devel libgphoto2-devel fontforge libusb-devel lcms2-devel audiofile-devel -y 2>&1 >>$log

    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/isdn4k-utils-3.2-99.el7.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/isdn4k-utils-devel-3.2-99.el7.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/audiofile-0.3.6-9.el7.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/audiofile-devel-0.3.6-9.el7.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/qt-4.8.7-8.el7.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/libmng-1.0.10-14.el7.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/qt-x11-4.8.7-8.el7.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/qt-devel-4.8.7-8.el7.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/vulkan-loader-devel-1.2.148.0-1.el8.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install http://mirror.centos.org/centos/8/PowerTools/x86_64/os/Packages/mpg123-devel-1.25.10-2.el8.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install https://pkgs.dyn.su/el8/extras/x86_64/libvkd3d-1.1-3.el8.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install https://pkgs.dyn.su/el8/extras/x86_64/libvkd3d-devel-1.1-3.el8.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install https://pkgs.dyn.su/el8/multimedia/x86_64/libFAudio-20.07-1.el8.8_2.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install https://pkgs.dyn.su/el8/multimedia/x86_64/libFAudio-devel-20.07-1.el8.8_2.i686.rpm -y 2>&1 >>$log
    sudo -H dnf install https://pkgs.dyn.su/el8/multimedia/x86_64/libFAudio-20.07-1.el8.8_2.x86_64.rpm -y 2>&1 >>$log
    sudo -H dnf install https://pkgs.dyn.su/el8/multimedia/x86_64/libFAudio-devel-20.07-1.el8.8_2.x86_64.rpm -y 2>&1 >>$log

    sudo -H dnf install glibc-devel.i686 dbus-devel.i686 freetype-devel.i686 pulseaudio-libs-devel.i686 libX11-devel.i686 mesa-libGLU-devel.i686 libICE-devel.i686 libXext-devel.i686 libXcursor-devel.i686 libXi-devel.i686 libXxf86vm-devel.i686 libXrender-devel.i686 libXinerama-devel.i686 libXcomposite-devel.i686 libXrandr-devel.i686 mesa-libGL-devel.i686 mesa-libOSMesa-devel.i686 libxml2-devel.i686 zlib-devel.i686 gnutls-devel.i686 ncurses-devel.i686 sane-backends-devel.i686 libv4l-devel.i686 libgphoto2-devel.i686 libexif-devel.i686 lcms2-devel.i686 gettext-devel.i686 isdn4k-utils-devel.i686 cups-devel.i686 fontconfig-devel.i686 gsm-devel.i686 libjpeg-turbo-devel.i686 libtiff-devel.i686 unixODBC.i686 openldap-devel.i686 alsa-lib-devel.i686 audiofile-devel.i686 freeglut-devel.i686 giflib-devel.i686 gstreamer1-devel.i686 gstreamer1-plugins-base-devel.i686 libXmu-devel.i686 libXxf86dga-devel.i686 libieee1284-devel.i686 libpng-devel.i686 librsvg2-devel.i686 libstdc++-devel.i686 libusb-devel.i686 unixODBC-devel.i686 qt-devel.i686 libpcap-devel.i686 -y 2>&1 >>$log

    echo "Resolving conflicts..."
    sudo -H dnf clean all 2>&1 >>$log
    sudo -H dnf update --best --allowerasing -y 2>&1 >>$log
    sudo -H dnf builddep wine -y 2>&1 >>$log
    sudo -H dnf update -y 2>&1 >>$log

    sudo -H dnf install gstreamer1-plugins-base-devel.{x86_64,i686} gstreamer1-devel.{x86_64,i686} systemd-devel.{x86_64,i686} -y 2>&1 >>$log

    sudo -H dnf install libXfixes-devel.{x86_64,i686} -y 2>&1 >>$log

fi

DOWNLOADS="${WORKSPACE}/downloads"
if [ ! -d "$DOWNLOADS" ]; then
	mkdir -pv "${DOWNLOADS}"
fi
wget "http://dl.winehq.org/wine/source/${WINE_VER_URL}/wine-${WINE_VER}.tar.xz" -O "${DOWNLOADS}/wine-${WINE_VER}.tar.xz" 2>&1 >>$log
# Use this url for experimental version.
# wget "http://dl.winehq.org/wine/source/${WINE_VER_MAJOR}.x/wine-${WINE_VER}.tar.xz" -O

SRC_DIR="${WORKSPACE}/src"
if [ ! -d "${SRC_DIR}" ]; then
	mkdir -pv "${SRC_DIR}"
fi
tar xf "${DOWNLOADS}/wine-${WINE_VER}.tar.xz" -C "${SRC_DIR}"
WINE_SRC_DIR="${SRC_DIR}/wine-${WINE_VER}"

WINE_BUILD_DIR_32="${WORKSPACE}/build/wine-${WINE_VER}-i686-build"
WINE_BUILD_DIR_64="${WORKSPACE}/build/wine-${WINE_VER}-x86_64-build"
if [ ! -d "$WORKSPACE/build" ]; then
	mkdir -pv "$WORKSPACE/build"
fi
mkdir -pv "$WINE_BUILD_DIR_32"
mkdir -pv "$WINE_BUILD_DIR_64"

echo "Configuring 64 bit Wine..."
cd "$WINE_BUILD_DIR_64" && CC="/usr/bin/gcc" CXX="/usr/bin/g++" CFLAGS="-O3 -march=native -pipe" CXXFLAGS="-O3 -march=native -pipe" LDFLAGS="-Wl,-rpath=$HOME/.local/lib -Wl,-rpath=$HOME/.local/lib64" "${WINE_SRC_DIR}/configure" \
	--prefix="$HOME/.local" --enable-win64 && cd "$CWD" 2>&1 >>$log

echo "Building 64 bit Wine (Wine64)..."
cd "${WINE_BUILD_DIR_64}" && make -j4 && cd "${CWD}" 2>&1 >>$log

echo "Configuring 32 bit Wine..."
cd "$WINE_BUILD_DIR_32" && CC="/usr/bin/gcc" CXX="/usr/bin/g++" CFLAGS="-O3 -march=native -pipe" CXXFLAGS="-O3 -march=native -pipe" LDFLAGS="-Wl,-rpath=$HOME/.local/lib" "${WINE_SRC_DIR}/configure" \
	--prefix="$HOME/.local" --with-wine64="${WINE_BUILD_DIR_64}" && cd "$CWD" 2>&1 >>$log

echo "Building 32 bit Wine... and Installing it into prefix directory."
cd "${WINE_BUILD_DIR_32}" && make -j 4 && make install 2>&1 >>$log
cd "${WINE_BUILD_DIR_64}" && make install 2>&1 >>$log

# wget https://dl.winehq.org/wine/wine-mono/6.0.0/wine-mono-6.0.0-x86.msi -O "$DOWNLOADS/wine-mono-6.0.0-x86.msi"
# wine msiexec /i $DOWNLOADS/wine-mono-6.0.0-x86.msi

#wget http://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86.msi -O "$DOWNLOADS/wine-gecko-2.47.2-x86.msi"
#wine msiexec /i $DOWNLOADS/wine-gecko-2.47.2-x86.msi
#wget http://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86_64.msi -O "$DOWNLOADS/wine-gecko-2.47.2-x86_64.msi"
#wine msiexec /i $DOWNLOADS/wine-gecko-2.47.2-x86_64.msi

#rm -rf "${WORKSPACE}"
#echo "Cleaned up all the build craps! Consider installing Winetricks."

echo "Checking the installation results..."
echo "Wine 32 bit is..."
file "$(command -v wine)"
echo "Wine 32 bit version is:"
wine --version
echo
echo "Wine 64 bit is..."
file "$(command -v wine64)"
echo "Wine 64 bit version is:"
wine64 --version
