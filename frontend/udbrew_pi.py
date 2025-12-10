#!/usr/bin/env python3
"""
    udbrew_pi.py

    A simple utility installation script for Raspberry PI's Raspbian
    environment. This script is a kind of extension of udbrew.py
    for the Raspbian environment and not here to replace the original
    one. 

"""

import os
import sys
import argparse

from src.Utils import RunCmd, program_exists
from src.RustTools import InstallRustTools
from src.NerdFonts import NerdFonts

# Some Nerdfonts to install
#  Do not add more fonts than those... 
#  It can prevent GUI to run
#
Nerd_Fonts_To_Install = [
    "BitstreamVeraSansMono",
    "Mononoki",
    "JetBrainsMono"
]

# Default installation path for programs and scripts. It is the default
# homebrew directory of udbrew.py: $HOME$/.local
#
HomeBrewDir = os.path.join(os.environ['HOME'], '.local')

# Golang and Duf
#
GoLangVersion = '1.25.4'
#GoLangTGTDir = os.path.join(HomeBrewDir, '.opt') + os.sep
GoLangTGTDir = '/opt/'
DufGit = 'https://github.com/muesli/duf.git'

# Essential programs to run this script. Obviously python is needed to 
# run this program.
#
prereq_commands = ['git', 'wget', 'curl', 'apt-get', 'tar']


class UDSBrewPi(RunCmd):
    """
        Main front end.. for Raspberry pi stuffs...

    """

    def __init__(self, args):
        """
            Initialize the class.

        """
        RunCmd.__init__(self, shell_type="bash", verbose=True)

        self.args = args
        self.parse_args()
        self.TestCMDs()

        print("Updating the Pi with apt...")
        self.Run("sudo -H apt-get update && sudo apt-get -y upgrade")

        self.package_list = []
        this_dir = os.path.realpath(__file__)
        self.package_file = os.path.join(
            os.path.dirname(this_dir), 'data', 'Raspbian_pkgs')

        self.ReadInPkgList()

        self.pi_model = None
        self.pi_gen = None
        self.architecture = ''
        self.ProbeOS()

        if self.p_args.prereq:
            self.InstallPiPackages()
            self.InstallNodeJS()

            if self.pi_gen >= 4:
                self.InstallVSCode()
            self.InstallBTop()
            self.InstallRubyPkgs()
            self.InstallStarship()
            self.NFInst = NerdFonts(NerdFontNames=Nerd_Fonts_To_Install)

        if self.p_args.rust_tools:
            InstallRustTools(raspberry_pi=True)

        if self.p_args.nodejs:
            self.InstallNodeJS()
        if self.p_args.golang:
            self.InstallGolang()
        if self.p_args.duf:
            self.InstallDuf()
        if self.p_args.btop:
            self.InstallBTop()

    def ReadInPkgList(self):
        self.package_list = []
        with open(self.package_file, 'r') as fp:
            pkg_list = [_.strip() for _ in fp.readlines()]
            for pkg in pkg_list:
                if '#' in pkg:
                    self.package_list.append(pkg.split('#')[0].strip())
                    continue
                if not pkg:
                    continue

                self.package_list.append('pkg')

        self.package_list = pkg_list
        print('Total {} packages will be installed via apt'
              .format(len(self.package_list)))

    def ProbeOS(self):
        """
            Detecting hardware specification.
            Mainly the pi's generation and OS bits.

        """

        self.pi_model = \
            self.RunSilent('sudo -H cat /sys/firmware/devicetree/base/model')[0]
        self.pi_gen = int(self.pi_model.split(' ')[2])

        uname_m = self.RunSilent('uname -m')[0].rstrip()

        if uname_m == 'aarch64':
            self.architecture = 'arm64'
        elif 'armv' in uname_m:
            self.architecture = 'arm32'

        print("RPi Architecture: {}".format(self.architecture))

    def TestCMDs(self):
        """
            Testing out critical commands if they exists in the system.
        """
        for pcmd in prereq_commands:
            if not program_exists(pcmd):
                print("We need {} to run this script!".format(pcmd))
                sys.exit(1)
        print("Prerequisite command test done!!")


    def InstallPiPackages(self):
        if self.package_list:
            print("Installing packages...")

            pkg_list_inline = ' '.join(self.package_list)
            self.Run('sudo -H apt-get -y install {}'.format(pkg_list_inline))

            print("Done!!")

        else:
            pass

    def InstallNodeJS(self, inst_ver='LTS'):
        """
            Reference:
            https://pimylifeup.com/raspberry-pi-nodejs/

        """
        if program_exists('node'):
            return

        print("Installing NodeJS")
        if inst_ver == 'LTS':
            self.Run("curl -fsSL https://deb.nodesource.com/setup_lts.x "
                     "| sudo -E bash -")
        elif inst_ver == 'Current':
            self.Run("curl -fsSL https://deb.nodesource.com/setup_current.x "
                     "| sudo -E bash -")
        self.Run("sudo apt-get install nodejs")

    def InstallGolang(self, inst_ver=GoLangVersion):
        """
            Installing golang from binary. Arm64 only!!

        """

        if program_exists('go'):
            print('Golang is already installed!!')
            return

        print("Installing Golang")

        if self.architecture == 'arm32':
            platform = 'armv6l'
        elif self.architecture == 'arm64':
            platform = self.architecture

        GoLangLink = 'https://go.dev/dl/go{}.linux-{}.tar.gz'\
                .format(inst_ver, platform)
        GoLangBinArchName = GoLangLink.split('/')[-1]

        InstDir = GoLangTGTDir
        if not os.path.exists(InstDir):
            os.mkdir(InstDir)

        install_cmds = [
            "cd /tmp",
            "wget {} -O {}".format(GoLangLink, GoLangBinArchName),
            "sudo tar xf {} -C {}".format(GoLangBinArchName, InstDir),
            "cd -"
        ]

        res = self.Run(cmd=' && '.join(install_cmds))[1]
        if res == 0:
            print("Make sure {} is in your path! And GOPATH".format(
                os.path.join(InstDir, 'go/bin')))
        else:
            print("Golang installation failed!")


    def InstallDuf(self):
        """
            Installing the disk space checking utility 'duf'

        """

        self.InstallGolang()

        if program_exists('duf'):
            print('duf is already installed!!')
            return

        current_dir = self.RunSilent('pwd')[0]

        InstDir = HomeBrewDir
        install_cmds = [
            "cd /tmp",
            "rm -rf /tmp/duf",
            "git clone {}".format(DufGit),
            "cd /tmp/duf",
            "go build",
            "cp -vf ./duf {}{}".format(os.path.join(InstDir, 'bin'), os.sep),
            "cd {}".format(current_dir)
        ]

        self.Run(cmd=' && '.join(install_cmds))

    def InstallVSCode(self):
        """
            Installing the VSCode via command line.
            Reference:
            https://edgoad.com/2021/02/installing-vs-code-on-raspberry-pi.html

        """

        if program_exists('code'):
            return

        if self.pi_gen < 4:
            print("Pi Generation {} is not powerful enough to run VSCode!!"
                  .format(self.pi_gen))
            return

        print("Installing VSCode")
        vscode_install_cmds = [
            "cd /tmp",
            "wget -qO- https://packages.microsoft.com/keys/microsoft.asc "
            "| gpg --dearmor > packages.microsoft.gpg",
            "sudo install -o root -g root -m 644 packages.microsoft.gpg "
            "/etc/apt/trusted.gpg.d/",
            "sudo sh -c \'echo \"deb [arch=amd64,arm64,armhf "
            "signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] "
            "https://packages.microsoft.com/repos/code stable main\" "
            "> /etc/apt/sources.list.d/vscode.list\'",
            "sudo apt-get install -y apt-transport-https",
            "sudo apt-get update && sudo apt-get install -y code",
            "cd -"
            ]
        self.Run(cmd=' && '.join(vscode_install_cmds))

    def InstallBTop(self):
        """
            Installing the btop++ for raspberry pi.

            Reference:
            https://lindevs.com/install-btop-on-raspberry-pi

            Now btop can be compiled on Pi

        """

        if program_exists('btop'):
            return

        print("Installing BTop++")
        # self.Run("cd /tmp && wget -qO btop.tbz "
        #         "https://github.com/aristocratos/btop/releases/"
        #        "latest/download/btop-armv7l-linux-musleabihf.tbz "
        #         "&& sudo tar xf btop.tbz --strip-components=2 -C "
        #         "/usr/local ./btop/bin/btop")
        self.Run("cd /tmp && rm -rf ./btop && "
                 "git clone https://github.com/aristocratos/btop.git /tmp/btop &&"
                 "cd /tmp/btop &&"
                 "make ADDFLAGS=-march=native && sudo make install")

    def InstallStarship(self):
        """
            Installing starship shell extension.

        """
        if program_exists('starship'):
            return
        print("\n\n\nInstalling Starship\n\n\n")
        self.Run("curl -sS https://starship.rs/install.sh | sh")

    def InstallRubyPkgs(self):
        """
            Installing some ruby packages to run the main
            script

        """
        if not program_exists('ruby') or not program_exists('gem'):
            raise "We need Ruby package manager!!"

        self.Run("sudo -H gem install tty-spinner ruby-progressbar")

    def parse_args(self):
        p = argparse.ArgumentParser(prog="unix_dev_setup_pi")

        p.add_argument(
            '-rust',
            '--rust_tools',
            action='store_true',
            default=False,
            help='Installs Rust tools and stuff!'
        )

        p.add_argument(
            '-pr',
            '--prereq',
            action='store_true',
            default=False,
            help='Installs packages for doing some stuff!'
        )

        p.add_argument(
            '-n',
            '--nodejs',
            action='store_true',
            default=False,
            help='Installs NodeJS related stuffs'
        )

        p.add_argument(
            '-go',
            '--golang',
            action='store_true',
            default=False,
            help='Installs the Golang binary'
        )

        p.add_argument(
            '-duf',
            '--duf',
            action='store_true',
            default=False,
            help='Installs Duf, a golang based disk space tool'
        )

        p.add_argument(
            '-bt',
            '--btop',
            action='store_true',
            default=False,
            help='Installs btop++'
        )

        if len(self.args) > 1:
            self.p_args = p.parse_args(self.args[1:])
        else:
            p.print_help()
            sys.exit(0)

if __name__ == "__main__":
    UDSBrewPi(sys.argv)
