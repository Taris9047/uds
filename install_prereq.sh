#!/bin/bash -e

#
# TODO: Need to populate proper package list for other distros.
# There are tons of strange distros!!
# -> Ubuntu 20.04, Debian, Fedora (F33),
#    CentOS (8), RHEL (8), openSUSE Leap,
#    Manjaro
# are ok now.
#

IN=$(grep '^NAME' /etc/os-release)
DISTRO=$(echo $IN | sed -E 's/\"//g' | sed -E 's/NAME=//')
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "Detecting distro..."
echo "... Looks like your distro is: $DISTRO"

# Some Distro information
Debian_base=("Debian GNU/Linux")
Ubuntu_base=("Ubuntu" "Linuxmint" "Linux Mint" "Pop" "Pop\!_OS")
Ubuntu_1804_base=("elementary OS")
Fedora_base=("Fedora" "CentOS Linux" "CentOS Stream" "Red Hat Enterprise Linux")
openSUSE_base=("openSUSE" "openSUSE Leap")
Arch_base=("ArchLinux" "Manjaro Linux")

# Supported modes
# "Ubuntu" "Fedora" "Arch"
MODE=''
if [[ " ${Ubuntu_base[@]} " =~ " ${DISTRO} " ]]; then
  MODE="Ubuntu"
elif [[ " ${Ubuntu_1804_base[@]} " =~ " ${DISTRO} " ]]; then
  MODE="Ubuntu18.04"
elif [[ " ${Debian_base[@]} " =~ " ${DISTRO} " ]]; then
  MODE="Debian"
elif [[ " ${Fedora_base[@]} " =~ " ${DISTRO} " ]]; then
  MODE="Fedora"
elif [[ " ${Arch_base[@]} " =~ " ${DISTRO} " ]]; then
  MODE="Arch"
elif [[ " ${openSUSE_base[@]} " =~ " ${DISTRO} " ]]; then
  MODE="openSUSE"
fi

echo "Current linux distribution seems $MODE based one."

readarray -t Debian_packages < "$SCRIPTPATH/data/ubuntu_pkgs"
readarray -t Ubuntu_packages < "$SCRIPTPATH/data/ubuntu_pkgs"
readarray -t Ubuntu_1804_packages < "$SCRIPTPATH/data/ubuntu_18.04_pkgs"
readarray -t Fedora_packages < "$SCRIPTPATH/data/fedora_pkgs"
readarray -t RHEL_packages < "$SCRIPTPATH/data/rhel_pkgs"
readarray -t Arch_packages < "$SCRIPTPATH/data/arch_pkgs"

Ruby_gems=( \
  "open3" \
  "json" \
  "ruby-progressbar" \
  "tty-spinner" \
  "lolcat" \
  )

#
# Note on open3: Ruby 2.5.. which comes with CentOS/RHEL cannot support
# newer 0.1.1 version. So, 0.1.0 will be installed on those systems.
# Let's hope they can work with my codes without too much problem.
#
Ruby_gems_RHEL=( \
  "json" \
  "ruby-progressbar" \
  "tty-spinner" \
  "lolcat" \
)

array_to_string ()
{
  arr=("$@")
  echo ${arr[*]}
}

install_prereq_Ubuntu ()
{
  pkgs=$( array_to_string "${Ubuntu_packages[@]}")
  gems=$( array_to_string "${Ruby_gems[@]}")
  sudo -H apt-get -y update && sudo apt-get -y upgrade
  sudo -H apt-get -y install $pkgs
  sudo -H /usr/bin/gem install $gems
}

install_prereq_Ubuntu1804()
{
  pkgs=$( array_to_string "${Ubuntu_1804_packages[@]}")
  gems=$( array_to_string "${Ruby_gems_RHEL[@]}")
  sudo -H apt-get -y update && sudo apt-get -y upgrade
  sudo -H apt-get -y install $pkgs
  sudo -H /usr/bin/gem install $gems
  sudo -H /usr/bin/gem install open3 -v 0.1.0
}

install_prereq_Debian ()
{
  install_prereq_Ubuntu
#  pkgs=$( array_to_string "${Debian_packages[@]}")
#  gems=$( array_to_string "${Ruby_gems[@]}")
#  sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y install $pkgs
#  sudo /usr/bin/gem install $gems
}

install_prereq_Fedora ()
{

  gems=()
  # Fedora
  if [[ "$DISTRO" == *"Fedora"* ]]; then
    pkgs=$( array_to_string "${Fedora_packages[@]}" )
    sudo -H dnf -y groupinstall "Development Tools" "Development Libraries"
    gems=$( array_to_string "${Ruby_gems[@]}")
    sudo -H dnf -y update && sudo dnf -y upgrade
    sudo -H dnf -y install $pkgs
    sudo -H /usr/bin/gem install $gems
  # In case CentOS or RHEL
  elif [[ "$DISTRO" == *"CentOS Linux"* || "$DISTRO" == *"Red Hat Enterprise Linux"* ]]; then
    pkgs=$( array_to_string "${RHEL_packages[@]}")
    sudo dnf -y install dnf-plugins-core
    if [[ "$DISTRO" == *"CentOS Linux"* ]]; then
      echo "Installing CentOS repos."
      sudo -H dnf -y install epel-release
      sudo -H dnf config-manager --set-enabled powertools
    elif [[ "$DISTRO" == *"Red Hat Enterprise Linux"* ]]; then
      echo "Working with RHEL8 repos.."
      sudo -H subscription-manager repos --enable "codeready-builder-for-rhel-8-$(arch)-rpms"
      sudo -H dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    fi
    sudo -H dnf -y groupinstall "Development Tools" "Additional Development"
    gems=$( array_to_string "${Ruby_gems_RHEL[@]}")
    sudo -H dnf -y update && sudo dnf -y upgrade
    sudo -H dnf -y install $pkgs
    sudo -H /usr/bin/gem install $gems
    sudo -H /usr/bin/gem install open3 -v 0.1.0
  fi
}

install_prereq_Arch ()
{
  pkgs=$( array_to_string "${Arch_packages[@]}" )
  gems=$( array_to_string "${Ruby_gems[@]}" )
  sudo -H pacman -Syyu --noconfirm $pkgs
  /usr/bin/gem install $gems
}

install_prereq_openSUSE ()
{
  pkgs=$( array_to_string "${openSUSE_packages[@]}" )
  gems=$( array_to_string "${Ruby_gems_RHEL[@]}" )
  sudo -H zypper refresh && sudo zypper update
  sudo -H zypper install --type pattern devel_basis
  sudo -H zypper install --type pattern devel_C_C++
  sudo -H zypper in $pkgs
  sudo -H /usr/bin/gem install $gems
  sudo -H /usr/bin/gem install open3 -v 0.1.0
}

case ${MODE} in

  "Ubuntu")
    install_prereq_Ubuntu
    ;;
  "Ubuntu18.04")
    install_prereq_Ubuntu1804
    ;;
  "Debian")
    install_prereq_Debian
    ;;
  "Fedora")
    install_prereq_Fedora
    ;;
  "Arch")
    install_prereq_Arch
    ;;
  "openSUSE")
    install_prereq_openSUSE
    ;;
  *)
    echo "${MODE} is not supported now."
    exit 1
    ;;
esac

# Putting up some system info!
if [ -x "$(command -v neofetch)" ]; then
  clear
  neofetch
fi

echo ""
echo "=========================================="
echo "| Prereq. package installation finished! |"
echo "|                                        |"
echo "| Now we can run ./unix_dev_setup.rb     |"
echo "|                                        |"
echo "| Hopefully, it compiles everything fine.|"
echo "=========================================="
echo ""

