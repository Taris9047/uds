#!/usr/bin/env python3

# Handles Rust installation.
from .Utils import RunCmd, program_exists
import os

Rust_packages = [
    "exa",
    "eza",
    "bat",
    "rm-improved",
    "diskonaut",
    "lsd",
    "cargo-update",
    "tokei",
    "fd-find",
    "procs",
    "du-dust",
    "ripgrep",
    "hyperfine",
    "ddh",
    "bottom",
    "zoxide",
    "broot",
    "git-delta"
]

Rust_packages_pi = [
    "eza",
    "bat",
    "rm-improved",
    "cargo-update",
    "fd-find",
    "du-dust"
]


class InstallRustTools(RunCmd):
    def __init__(self, reinstall_pkgs=False,
                 default_cargo_path=None,
                 raspberry_pi=False):
        RunCmd.__init__(self, verbose=True)

        if not raspberry_pi:
            self.Packages = Rust_packages
        else:
            self.Packages = Rust_packages_pi

        self.home_dir = os.getenv("HOME")
        self.default_cargo_path = None
        if not default_cargo_path:
            self.default_cargo_path = \
                os.path.join(self.home_dir, ".cargo", "bin")
        else:
            self.default_cargo_path = default_cargo_path

        self.cargo_exec = os.path.join(self.default_cargo_path, "cargo")
        self.rustup_exec = os.path.join(self.default_cargo_path, "rustup")

        self.pkgs_to_install = Rust_packages
        self.reinstall_pkgs = reinstall_pkgs

        # Checking up if Rust in our local directory exists.
        if program_exists(self.cargo_exec) and \
                program_exists(self.rustup_exec):
            self.CargoUpdate()
            # self.InstallPackages()
        else:
            self.InstallNew()

    def CargoUpdate(self):
        print("Upgrading rustc")
        self.Run(f"rustup upgrade")
        print("Updating currently installed Rust packages!!")
        for rpk in self.Packages:
            self.Run(f"{self.cargo_exec} install {rpk}")
        self.Run(f"{self.cargo_exec} install cargo-update")
        self.Run(f"{self.rustup_exec} update stable")

        self.Run(f"{self.cargo_exec} install-update -a")

    def InstallNew(self):
        env_script = os.path.join(self.default_cargo_path, "..", "env")
        print("Looks like we do not have Rust on the system! "
              "Installing Rust!!")
        self.Run(
            "curl --proto '=https' --tlsv1.2 -sSf "
            "https://sh.rustup.rs | sh -s -- -y"
        )
        print("Updating environment!")
        self.Run(f"source {env_script}")
        self.InstallPackages()
        print(
            "Check up your shell environment files (i.e. .bashrc)"
            " if additional cargo env line was added.")

    def InstallPackages(self):
        self.Run(f"{self.rustup_exec} component add rust-src")
        self.Run(f"{self.cargo_exec} install {' '.join(self.pkgs_to_install)}")
        # Installing starship with '--locked' parameter
        # self.Run(f"{self.cargo_exec} install starship --locked")
        # Now we aren't particularily interested in the starship via 
        # cargo installation. 
        # We would rather use binary installation...


