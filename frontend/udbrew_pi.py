#!/usr/bin/env python3
import os
import sys
# import subprocess

import argparse

from src.Utils import RunCmd, program_exists
from src.RustTools import InstallRustTools


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

        print("Updating the Pi with apt...")
        self.Run("sudo -H apt-get update && sudo apt-get -y upgrade")

        self.package_list = []
        this_dir = os.path.realpath(__file__)
        self.package_file = os.path.join(
            os.path.dirname(this_dir), 'data', 'Raspbian_pkgs')

        self.ReadInPkgList()

        if self.p_args.prereq:
            self.InstallPiPackages()
            self.InstallNodeJS()

            self.pi_model = \
                self.RunSilent('sudo -H cat /sys/firmware/devicetree/base/model')[0]
            self.pi_gen = int(self.pi_model.split(' ')[2])
            if self.pi_gen >= 4:
                self.InstallVSCode()
            self.InstallBTop()

        if self.p_args.rust_tools:
            InstallRustTools(raspberry_pi=True)

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

    def InstallVSCode(self):
        """
            Installing the VSCode via command line.
            Reference:
            https://edgoad.com/2021/02/installing-vs-code-on-raspberry-pi.html

        """

        if program_exists('code'):
            return

        if self.pi_gen < 4:
            print("Pi Generation {} is not powerful enough"
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
            "sudo apt-get update && sudo apt install -y code",
            "cd -"
            ]
        self.Run(cmd=' && '.join(vscode_install_cmds))

    def InstallBTop(self):
        """
            Installing the btop++ for raspberry pi.

            Reference:
            https://lindevs.com/install-btop-on-raspberry-pi

        """

        if program_exists('btop'):
            return

        print("Installing BTop++")
        self.Run("cd /tmp && wget -qO btop.tbz "
                 "https://github.com/aristocratos/btop/releases/"
                 "latest/download/btop-armv7l-linux-musleabihf.tbz "
                 "&& sudo tar xf btop.tbz --strip-components=2 -C "
                 "/usr/local ./btop/bin/btop")

    def parse_args(self):
        p = argparse.ArgumentParser(prog="unix_dev_setup_pi")

        p.add_argument(
            '-rust',
            '--rust_tools',
            action='store_true',
            default=False,
            help='Installs Rust written stuff!'
        )

        p.add_argument(
            '-pr',
            '--prereq',
            action='store_true',
            default=True,
            help='Installs packages for doing some stuff!'
        )

        if len(self.args) > 1:
            self.p_args = p.parse_args(self.args[1:])
        else:
            p.print_help()
            sys.exit(0)

if __name__ == "__main__":
    UDSBrewPi(sys.argv)