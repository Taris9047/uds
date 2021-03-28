#!/usr/bin/env bash -e

CWD=$(pwd -P)

mkdir -pv "$CWD/workspace/downloads"
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O "$CWD/workspace/downloads/winetricks"
chmod +x "$CWD/workspace/downloads/winetricks"
cp "$CWD/workspace/downloads/winetricks" "$HOME/.local/bin/winetricks"
