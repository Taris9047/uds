#!/bin/bash

DEF_QT_VER="5.15.2"
if [ ! -z "$1"]; then
  DEF_QT_VER="$1"
fi

QT5PREFIX=$HOME/.Qt/$DEF_QT_VER/gcc_64

if [ -d "$QT5PREFIX" ]; then
  echo "Qt-$DEF_QT_VER found at $QT5PREFIX"
  echo "Working on pkgconfig massage!"
else
  echo "No Qt directory found! exiting!"
  exit -1
fi

# Sedwasy
function sedeasy {
  sed -i "s/$(echo $1 | sed -e 's/\([[\/.*]\|\]\)/\\&/g')/$(echo $2 | sed -e 's/[\/&]/\\&/g')/g" $3
}

for pc_file in "$QT5PREFIX/lib/pkgconfig"/*.pc
do
  # REAL_PATH="$QT5PREFIX/lib/pkgconfig/$pc_file"
  if [ -f "$pc_file" ]; then
    echo "Patching $pc_file"
    sedeasy '/home/qt/work/install' "$QT5PREFIX" "$pc_file"
  fi
done

echo "Patching done!"
