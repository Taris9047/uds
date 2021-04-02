#!/usr/bin/env python3

# Handles Rust installation.
from .Utils import RunCmd
import os

Rust_packages = [
    "exa",
    "bat",
    "rm-improved",
    # "diskonaut",
    "lsd",
    "cargo-update",
    "starship",
    "tokei",
    "fd-find",
    "procs",
    "du-dust",
    "ripgrep",
    # "hyperfine",
    # "eureka",
    "ddh",
    # "gitui",
    "ytop",
    # "grex",
    "zoxide",
    "broot",
]


class InstallRustTools(RunCmd):
    def __init__(self, reinstall_pkgs=False, default_cargo_path=None):
        RunCmd.__init__(self, verbose=True)

        self.default_cargo_path = None
        if not default_cargo_path:
            self.default_cargo_path = \
                os.path.join(os.getenv('HOME'), '.cargo', 'bin')
        else:
            self.default_cargo_path = default_cargo_path

        self.cargo_exec = os.path.join(self.default_cargo_path, 'cargo')
        self.rustup_exec = os.path.join(self.default_cargo_path, 'rustup')

        self.pkgs_to_install = Rust_packages
        self.reinstall_pkgs = reinstall_pkgs

        # Checking up if Rust in our local directory exists.
        if self.program_exists(self.cargo_exec) \
            and self.program_exists(self.rustup_exec):
            self.CargoUpdate()
        else:
            self.InstallNew()

    def CargoUpdate(self):
        print("Updating currently installed Rust packages!!")
        self.Run(f"{self.rustup_exec} update")
        self.Run(f"{self.cargo_exec} install-update -a")
        if self.reinstall_pkgs:
            self.InstallPackages()

    def InstallNew(self):
        print("Looks like we do not have Rust on the system! Installing Rust!!")
        self.Run("curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y")
        print("Updating environment!")
        self.Run("source $HOME/.bashrc")
        self.InstallPackages()
        print("Check up your $HOME/.bashrc to check up if additional cargo env line added.")

    def InstallPackages(self):
        self.Run(f"{self.cargo_exec} install {' '.join(self.pkgs_to_install)}")

    def program_exists(self, program=None):
        def is_exe(fpath):
            return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

        fpath, fname = os.path.split(program)
        if fpath:
            if is_exe(program):
                return True
        else:
            for path in os.environ["PATH"].split(os.pathsep):
                exe_file = os.path.join(path, program)
                if is_exe(exe_file):
                    return True

        return False
