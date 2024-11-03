#!/usr/bin/env python3

import os
import sys
import subprocess

import argparse

from src.Utils import RunCmd, program_exists, Version
from src.Editors import InstallEditors
from src.RubyGems import InstallSystemRubyGems
from src.Prerequisites import InstallPrereqPkgs
from src.RustTools import InstallRustTools
from src.PatchQt5WebInstall import PatchQt5WebInstall


class UDSBrew(RunCmd):
    """
    The front-end main class

    Yeap, organizes all the dirty works.
    """

    def __init__(self, args):
        """
        Initializing stuff.
        """
        RunCmd.__init__(self, shell_type="bash", verbose=True)

        self.script_path = os.path.realpath(__file__)
        self.exec_path = os.path.join(self.script_path, '..')

        self.update_self_repo()
        # self.update_database()
        self.find_out_version()
        self.fallback_ruby = "/usr/bin/ruby"  # Fallback. Does not work with many situations.

        print("Probing ruby...")
        self.system_ruby = subprocess.check_output("echo \"$(command -v ruby)\"", shell=True).decode('utf-8').rstrip()

        if program_exists(self.system_ruby):
            print(f"Ruby detected: {self.system_ruby}")
            if 'shims' in self.system_ruby:
                print("Looks like we have rbenv ruby! Using it!")
        else:
            self.system_ruby = self.fallback_ruby
            if not program_exists(self.system_ruby):
                self.InstallRuby()

            print("Using system wide ruby...: {}".format(self.system_ruby))

        self.args = args
        self.parse_args()

        self.opt_sgcc = ""
        self.opt_verbose = "-v"

        if self.p_args.prerequisite:
            self.InstallPrerequisiteStuffs()

        if self.p_args.list:
            self.Run(f"{self.system_ruby} {self.uds_backend} list")
            sys.exit(0)

        if self.p_args.rust_tools:
            InstallRustTools()
            sys.exit(0)

        if self.p_args.clean:
            self.Run(f"{self.system_ruby} {self.uds_backend} clean")
            sys.exit(0)

        if self.p_args.purge:
            self.Run(f"{self.system_ruby} {self.uds_backend} purge")
            sys.exit(0)

        if self.p_args.version:
            self.show_version()
            sys.exit(0)

        if len(self.p_args.editors) > 0:
            InstallEditors(self.p_args.editors)
            sys.exit(0)

        if self.p_args.qt5_patch:
            qt5_version = self.p_args.qt5_patch[0]
            qt5path = self.p_args.qt5_patch[1]
            PatchQt5WebInstall(qt5_version, qt5path)

        if len(self.p_args.install) > 0:
            pkgs_to_install = set(self.p_args.install)

            p_args_inst = argparse.ArgumentParser()
            p_args_inst.add_argument(
                "-sgcc",
                "--system_gcc",
                action="store_true",
                default=False,
                help="Prefers system gcc instead of homebrewed one.",
            )
            p_args_inst.add_argument(
                "-q",
                "--quiet",
                action="store_true",
                default=False,
                help="Prefers not so verbose.",
            )
            p_args_inst.add_argument(
                "pkgs_to_install",
                nargs="*",
                default=[],
                help="Installation options which will be fed into the ruby backend.",
            )

            parsed_inst_args = p_args_inst.parse_args(self.p_args.install)

            if parsed_inst_args.system_gcc:
                self.opt_sgcc = "-sgcc"

            if parsed_inst_args.quiet:
                self.opt_verbose = ""

            pkgs_to_install = set(parsed_inst_args.pkgs_to_install)

            if len(pkgs_to_install) == 0:
                print("Missing packages to install!!")
                sys.exit(0)

            for pkg in pkgs_to_install:
                self.Run(
                    f"{self.system_ruby} {self.uds_backend} {self.opt_verbose} {self.opt_sgcc} {pkg}"
                )

            sys.exit(0)

        if len(self.p_args.uninstall) > 0:
            pkgs_to_uninstall = set(self.p_args.uninstall)

            for pkg in pkgs_to_uninstall:
                self.Run(f"{self.system_ruby} {self.uds_backend} {self.opt_verbose} -u {pkg}")

            sys.exit(0)

    def InstallRuby(self):
        print ('Installing Ruby before running this script...')
        #if program_exists('/usr/bin/apt'):
        #    self.Run('sudo apt update && sudo apt install ruby')
        if program_exists('/usr/bin/apt-get'):
            self.Run('sudo apt-get update && sudo apt-get install ruby')
        elif program_exists('/usr/bin/dnf'):
            self.Run('sudo dnf update && sudo dnf install ruby')
        elif program_exists('/usr/bin/yum'):
            self.Run('sudo yum update && sudo yum install ruby')
        else:
            self.Run("/bin/sh {}".format(os.path.join(self.exec_path, "install_rbenv.sh")))
            print("Run . ~/.bashrc or something similar and run this script again!!")
            sys.exit(0)

    def InstallPrerequisiteStuffs(self):
        """
        Installs Prerequisite packages (selected by subroutines)
        and ruby gems that we need to run those ruby scripts!
        """
        print("Installing Programs and Packages from the System's own repository!!\n")
        InstallPrereqPkgs()
        print("Done!\n")

        print("Installing Gems for the system Ruby for backend operation!!\n")
        InstallSystemRubyGems()

        print("\nDone!!\n")
        sys.exit(0)

    def parse_args(self):
        """
        Parses command line arguments for the backend.

        """
        p = argparse.ArgumentParser(prog="unix_dev_setup")

        p.add_argument(
            "-i",
            "--install",
            metavar="<package_name>",
            nargs="*",
            default=[],
            help="Installs given packages.",
        )
        p.add_argument(
            "-u",
            "--uninstall",
            metavar="<package_name>",
            nargs="*",
            default=[],
            help="Uninstalls given packages.",
        )
        p.add_argument(
            "--clean",
            action="store_true",
            default=False,
            help="Clean up current pkginfo and work directories to start anew. But not deleting already installed packages.",
        )
        p.add_argument(
            "--purge",
            action="store_true",
            default=False,
            help="Cleans up every single craps!! To start anew!!!",
        )
        p.add_argument(
            "-pr",
            "--prerequisite",
            action="store_true",
            default=False,
            help="Installs prerequisite packages depending on system's Linux distribution.",
        )
        p.add_argument(
            "-v",
            "--version",
            action="store_true",
            dest="version",
            default=False,
            help="Show version",
        )
        p.add_argument(
            "-l",
            "--list",
            action="store_true",
            default=False,
            help="List available packages",
        )
        p.add_argument(
            "-o",
            "--options",
            metavar="<options>",
            nargs="*",
            choices=["sgcc", "verbose"],
            default=[],
            help="Installation options.",
        )
        p.add_argument(
            "-ed",
            "--editors",
            metavar="<external_editor>",
            nargs="*",
            choices=["sublime-text", "subl", "sublime", "vscode", "code", "atom", "jedit"],
            default=[],
            help="Installs some pre-built editors such as sublime-text, Visual Studio Code, Atom.",
        )
        p.add_argument(
            "-rust",
            "--rust_tools",
            action="store_true",
            default=False,
            help="Installs super useful utilities written by Rust",
        )
        p.add_argument(
            "-qt5patch",
            "--qt5-patch",
            metavar="<qt5_version>",
            nargs="*",
            default=[],
            help="Patches weird pkgconfig files on Web installed Qt5.",
        )

        if len(self.args) > 1:
            self.p_args = p.parse_args(self.args[1:])
        else:
            p.print_help()
            sys.exit(0)

    def show_version(self):
        """
        Displays the version we extracted to stdio
        """
        print(f"unix_dev_setup {'.'.join(self.version)}")

    def find_out_version(self):
        """
			Extracts version from the VERSION file.
			
        """
        self.uds_backend = "./unix_dev_setup.rb"
        if os.path.exists("./unix_dev_setup"):
            self.uds_backend = "./unix_dev_setup"

        self.VERSION_file = os.path.join(os.path.realpath('./'), "VERSION")
        if not os.path.exists(self.VERSION_file):
            raise FileNotFoundError("Version file does not exist!!: {}".format(self.VERSION_file))

        self.version = None

        with open(self.VERSION_file, "r") as fp:
            while True:
                print(self.VERSION_file)
                line = fp.readline()
                if line:
                    ver = line.strip()
                    self.version = Version(ver)
                    print(self.version)
                else:
                    break


            if not self.version:
                print("Unable to obtain version information from backend!!")
                print(
                    "> Care to check up whether we have unix_dev_setup in the same path?"
                )

    # Runs 'git pull' every time
    def update_self_repo(self):
        print("Running self update ...")
        self.Run('git pull')

    # Runs hjson update
    def update_database(self):
        print("Running Database update ...")
        self.Run('sh -c ./data/update_json.sh')

if __name__ == "__main__":
    UDSBrew(sys.argv)
