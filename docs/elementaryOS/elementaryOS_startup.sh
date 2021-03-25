sudo apt install software-properties-common

sudo add-apt-repository ppa:philip.scott/elementary-tweaks
sudo apt update
sudo apt install elementary-tweaks

sudo apt install ubuntu-restricted-extras libavccodec-extra libdvd-pkg

sudo ubuntu-drivers autoinstall

sudo sed -i \
    's/OnlyShowIn\=Unity\;GNOME\;/OnlyShowIn\=Unity\;GNOME\;Pantheon\;/' \
    /etc/xdg/autostart/indicator-application.desktop
wget \
    http://ppa.launchpad.net/elementary-os/stable/ubuntu/pool/main/w/wingpanel-indicator-ayatana/wingpanel-indicator-ayatana_2.0.3+r27+pkg17~ubuntu0.4.1.1_amd64.deb
sudo dpkg -i \
    ./wingpanel-indicator-ayatana_2.0.3+r27+pkg17~ubuntu0.4.1.1_amd64.deb
sudo mv /etc/xdg/autostart/nm-applet.desktop \
    /etc/xdg/autostart/nm-applet.desktop.old
rm -rf \
    ./wingpanel-indicator-ayatana_2.0.3+r27+pkg17~ubuntu0.4.1.1_amd64.deb

sudo apt install synaptic

sudo apt install firefox

sudo apt install libreoffice libreoffice-gtk3 libreoffice-style-elementary

sudo apt install com.github.devidmhewitt.clipped

sudo apt install gdebi

sudo apt install tlp tlp-rdw
