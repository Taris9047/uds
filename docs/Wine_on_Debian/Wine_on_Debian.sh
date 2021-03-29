#!/usr/bin/env bash -e
echo "Adding 32bit repo..."
sudo -H dpkg --add-architecture i386 2&>1 /dev/null

echo "Adding WineHq repository for Debian 10 Buster"
wget -O- -q  https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/Release.key | sudo apt-key add -    2&>1 /dev/null
echo "deb http://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10 ./" | sudo tee /etc/apt/sources.list.d/wine-obs.list 2&>1 /dev/null

sudo -H apt update 2&>1 /dev/null
sudo -H apt -y install --install-recommends winehq-stable 2&>1 /dev/null

wine --version

wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks 2&>1 /dev/null
chmod +x ./winetricks
sudo -H mv ./winetricks /usr/local/bin/winetricks
sudo -H apt -y install cabextract 2&>1 /dev/null
