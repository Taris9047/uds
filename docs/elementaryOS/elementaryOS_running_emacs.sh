sudo add-apt-repository ppa:kellyk/emacs
sudo apt-get update

sudo apt-get install emacs27

sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install -y git

alias emacs='XLIB_SKIP_ARGB_VISUALS=1 emacs'
