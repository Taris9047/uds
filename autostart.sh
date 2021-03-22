#!/bin/bash

# Run this to automate everything...

source ./install_prereq.sh

source ./setup_editors.sh

source ./setup_rust.sh

if [ ! -d ./pkginfo ]; then
  /usr/bin/ruby ./unix_dev_setup.rb -v all
fi