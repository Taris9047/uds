#!/usr/bin/env python3

import os
import sys
import subprocess

import argparse

from src.Utils import RunCmd, program_exists
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

        self.find_out_version()
        self.system_ruby = "/usr/bin/ruby" # Fallback. Does not work with many situations.
        self.ruby = subprocess.check_output( "$(command -v ruby)", shell=True )
        if not program_exists(self.system_ruby):
            print("Oh crap, we need ruby to work correctly!!")
            sys.exit(-1)
        if program_exists(self.ruby):
            self.system_ruby = self.ruby

        self.args = args
        self.parse_args()

        if self.p_args.prerequisite:
            self.InstallPrerequisiteStuffs()

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

            opt_sgcc = ""
            if parsed_inst_args.system_gcc:
                opt_sgcc = "-sgcc"

            opt_verbose = "-v"
            if parsed_inst_args.quiet:
                opt_verbose = ""

            pkgs_to_install = set(parsed_inst_args.pkgs_to_install)

            if len(pkgs_to_install) == 0:
                print("Missing packages to install!!")
                sys.exit(0)

            for pkg in pkgs_to_install:
                self.Run(
                    f"{self.system_ruby} {self.uds_backend} {opt_verbose} {opt_sgcc} {pkg}"
                )

            sys.exit(0)

        if len(self.p_args.uninstall) > 0:
            pkgs_to_uninstall = set(self.p_args.uninstall)

            for pkg in pkgs_to_uninstall:
                self.Run(f"{self.system_ruby} {self.uds_backend} -v {pkg}")

            sys.exit(0)

    def InstallPrerequisiteStuffs(self):
        """
        Installs Prerequisite packages (selected by subroutines)
        and ruby gems that we need to run those ruby scripts!
        """
        print ("Installing Programs and Packages from the System's own repository!!\n")
        InstallPrereqPkgs()
        print ("Done!\n")

        print ("Installing Gems for the system Ruby for backend operation!!\n")
        InstallSystemRubyGems()
        print ("\nDone!!\n")
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
            choices=["sublime-text", "subl", "vscode", "atom"],
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

    # def show_help(self):
    #     """
    #     DUMMY: Help message.
    #     TODO Fill out help message? Someday?
    #     """
    #     print("<Put help message here>")

    def show_version(self):
        """
        Displays the version we extracted to stdio
        """
        print(f"unix_dev_setup {'.'.join(self.version)}")

    def find_out_version(self):
        """
        Extracts version info from the backend
        unix_dev_setup.rb
        """
        self.uds_backend = "./unix_dev_setup.rb"
        if os.path.exists("./unix_dev_setup"):
            self.uds_backend = "./unix_dev_setup"

        self.version = None

        with open(self.uds_backend, "r") as fp:
            while True:
                line = fp.readline()
                if "$version" in line:
                    ver = line.split("=")[-1]
                    self.version = eval(ver)
                    break

            if not self.version:
                print("Unable to obtain version information from backend!!")
                print(
                    "> Care to check up whether we have unix_dev_setup in the same path?"
                )


if __name__ == "__main__":
    UDSBrew(sys.argv)
