#!/usr/bin/env python3

import os
import sys

import argparse

from src.Editors import InstallEditors
from src.RubyGems import InstallSystemRubyGems
from src.Prerequisites import InstallPrereqPkgs
from src.Utils import RunCmd, Version
# from src.RustTools import InstallRustTools # not implemented yet.

### Front End main class ###
###
### Organizes all the dirty jobs.
###
class UDSBrew(RunCmd):
    def __init__(self, args):
        RunCmd.__init__(self, shell_type="bash", verbose=True)

        self.find_out_version()

        self.args = args
        self.parse_args()

        if self.p_args.prerequisite:
            self.InstallPrerequisiteStuffs()

        if self.p_args.clean:
            self.Run(f"ruby ./unix_dev_setup clean")
            sys.exit(0)

        if self.p_args.purge:
            self.Run(f"ruby ./unix_dev_setup purge")
            sys.exit(0)

        if self.p_args.version:
            self.show_version()
            sys.exit(0)

        if len(self.p_args.editors) > 0:
            InstallEditors(self.p_args.editors)
            sys.exit(0)

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
                self.Run(f"ruby ./unix_dev_setup {opt_verbose} {opt_sgcc} {pkg}")

            sys.exit(0)

        if len(self.p_args.uninstall) > 0:
            pkgs_to_uninstall = set(self.p_args.uninstall)

            for pkg in pkgs_to_uninstall:
                self.Run(f"ruby ./unix_dev_setup -v {pkg}")

            sys.exit(0)

    def InstallPrerequisiteStuffs(self):
        InstallPrereqPkgs()
        InstallSystemRubyGems()
        sys.exit(0)

    def parse_args(self):

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

        if len(self.args) > 1:
            self.p_args = p.parse_args(self.args[1:])
        else:
            p.print_help()
            sys.exit(0)

    ### Help file
    def show_help(self):
        print("<Put help message here>")

    ### Show version
    def show_version(self):
        print(f"unix_dev_setup {'.'.join(self.version)}")

    ### Set Version ###
    ### finds unix_dev_setup.rb to extract version info.
    ###
    def find_out_version(self):
        uds_backend = "./unix_dev_setup.rb"
        if os.path.exists("./unix_dev_setup"):
            uds_backend = "./unix_dev_setup"

        self.version = None

        with open(uds_backend, "r") as fp:
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


### Calling main function ###
if __name__ == "__main__":
    UDSBrew(sys.argv)
