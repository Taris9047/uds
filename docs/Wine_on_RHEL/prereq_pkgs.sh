#!/bin/bash -e
CWD="$(pwd -P)"
if [ ! -d "${CWD}/workspace" ]; then
	mkdir -pv "${CWD}/workspace"
fi
WORKSPACE="${CWD}/workspace"
WINE_VER="7.0"
WINE_VER_MAJOR=$(echo ${WINE_VER} | cut -d'.' -f1)
WINE_VER_URL=$(echo ${WINE_VER} | cut -d'.' -f1,2)

log="$(mktemp -t install-wine.XXXXXX.log)"

# Checking for wget
if [ ! -x "$(command -v wget)" ]; then
	echo "Oops! wget is a must!!"
	exit 1
fi

NPROCS="$(grep -c processor /proc/cpuinfo)"
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

    # sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/isdn4k-utils-3.2-99.el7.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/isdn4k-utils-devel-3.2-99.el7.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/audiofile-0.3.6-9.el7.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/audiofile-devel-0.3.6-9.el7.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/qt-4.8.7-8.el7.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/libmng-1.0.10-14.el7.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/qt-x11-4.8.7-8.el7.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install http://mirror.centos.org/centos/7/os/x86_64/Packages/qt-devel-4.8.7-8.el7.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/vulkan-loader-devel-1.2.148.0-1.el8.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install http://mirror.centos.org/centos/8/PowerTools/x86_64/os/Packages/mpg123-devel-1.25.10-2.el8.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install https://centos.pkgs.org/8/raven-extras-x86_64/libvkd3d-1.2-10.el8.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install https://centos.pkgs.org/8/raven-extras-x86_64/libvkd3d-devel-1.2-10.el8.i686.rpm  -y 2>&1 >>$log
    # sudo -H dnf install https://centos.pkgs.org/8/raven-extras-x86_64/libFAudio-21.11-2.el8.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install https://centos.pkgs.org/8/raven-extras-x86_64/libFAudio-devel-21.11-2.el8.i686.rpm -y 2>&1 >>$log
    # sudo -H dnf install https://centos.pkgs.org/8/epel-x86_64/libFAudio-21.11-1.el8.x86_64.rpm -y 2>&1 >>$log
    # sudo -H dnf install https://centos.pkgs.org/8/raven-extras-x86_64/libFAudio-devel-21.11-2.el8.x86_64.rpm  -y 2>&1 >>$log

    sudo -H dnf install glibc-devel.i686 dbus-devel.i686 freetype-devel.i686 pulseaudio-libs-devel.i686 libX11-devel.i686 mesa-libGLU-devel.i686 libICE-devel.i686 libXext-devel.i686 libXcursor-devel.i686 libXi-devel.i686 libXxf86vm-devel.i686 libXrender-devel.i686 libXinerama-devel.i686 libXcomposite-devel.i686 libXrandr-devel.i686 mesa-libGL-devel.i686 mesa-libOSMesa-devel.i686 libxml2-devel.i686 zlib-devel.i686 gnutls-devel.i686 ncurses-devel.i686 sane-backends-devel.i686 libv4l-devel.i686 libgphoto2-devel.i686 libexif-devel.i686 lcms2-devel.i686 gettext-devel.i686 isdn4k-utils-devel.i686 cups-devel.i686 fontconfig-devel.i686 gsm-devel.i686 libjpeg-turbo-devel.i686 libtiff-devel.i686 unixODBC.i686 openldap-devel.i686 alsa-lib-devel.i686 audiofile-devel.i686 freeglut-devel.i686 giflib-devel.i686 gstreamer1-devel.i686 gstreamer1-plugins-base-devel.i686 libXmu-devel.i686 libXxf86dga-devel.i686 libieee1284-devel.i686 libpng-devel.i686 librsvg2-devel.i686 libstdc++-devel.i686 libusb-devel.i686 unixODBC-devel.i686 qt4-devel.i686 libpcap-devel.i686 -y 2>&1 >>$log

    echo "Resolving conflicts..."
    sudo -H dnf clean all 2>&1 >>$log
    sudo -H dnf update --best --allowerasing -y 2>&1 >>$log
    sudo -H dnf builddep wine -y 2>&1 >>$log
    sudo -H dnf update -y 2>&1 >>$log

    sudo -H dnf install gstreamer1-plugins-base-devel.{x86_64,i686} gstreamer1-devel.{x86_64,i686} systemd-devel.{x86_64,i686} -y 2>&1 >>$log

    sudo -H dnf install libXfixes-devel.{x86_64,i686} -y 2>&1 >>$log

fi
