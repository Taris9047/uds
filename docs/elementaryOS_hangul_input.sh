sudo apt install software-properties-common

curl -sL https://apt.hamonikr.org/setup_hamonikr.sun | sudo -E bash -

# curl -sL https://apt.hamonikr.org/setup_hamonikr.jin | sudo -E bash -

sudo apt update && sudo apt install -y nimf nimf-libhangul

sudo im-config -n nimf
