#!/usr/bin/env python3

# Handles Rust installation.
from .Utils import RunCmd, program_exists
import os

Rust_packages = [
    "exa",
    "bat",
    "rm-improved",
    "diskonaut",
    "lsd",
    "cargo-update",
    "starship",
    "tokei",
    "fd-find",
    "procs",
    "du-dust",
    "ripgrep",
    "hyperfine",
    # "eureka",
    "ddh",
    # "gitui",
    "bottom",
    # "grex",
    "zoxide",
    "broot",
]


class InstallRustTools(RunCmd):
    def __init__(self, reinstall_pkgs=False, default_cargo_path=None):
        RunCmd.__init__(self, verbose=True)

        self.home_dir = os.getenv("HOME")
        self.default_cargo_path = None
        if not default_cargo_path:
            self.default_cargo_path = os.path.join(self.home_dir, ".cargo", "bin")
        else:
            self.default_cargo_path = default_cargo_path

        self.cargo_exec = os.path.join(self.default_cargo_path, "cargo")
        self.rustup_exec = os.path.join(self.default_cargo_path, "rustup")

        self.pkgs_to_install = Rust_packages
        self.reinstall_pkgs = reinstall_pkgs

        # Checking up if Rust in our local directory exists.
        if program_exists(self.cargo_exec) and program_exists(self.rustup_exec):
            self.CargoUpdate()
        else:
            self.InstallNew()

    def CargoUpdate(self):
        print("Updating currently installed Rust packages!!")
        for rpk in Rust_packages:
            self.Run(f"{self.cargo_exec} install {rpk}")
        # self.Run(f"{self.cargo_exec} install cargo-update")
        self.Run(f"{self.rustup_exec} update stable")
        self.Run(f"{self.cargo_exec} install-update -a")

    def InstallNew(self):
        env_script = os.path.join(self.default_cargo_path, "..", "env")
        print("Looks like we do not have Rust on the system! Installing Rust!!")
        self.Run(
            "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
        )
        print("Updating environment!")
        self.Run(f"source {env_script}")
        self.InstallPackages()
        print(
            f"Check up your {self.home_dir}/.bashrc or .zshrc to check up if additional cargo env line added."
        )

    def InstallPackages(self):
        self.Run(f"{self.rustup_exec} component add rust-src")
        self.Run(f"{self.cargo_exec} install {' '.join(self.pkgs_to_install)}")
