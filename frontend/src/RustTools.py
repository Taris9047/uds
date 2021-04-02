#!/usr/bin/env python3

# Handles Rust installation.

Rust_packages = []

from .Utils import RunCmd

class InstallRustTools(RunCmd):
    def __init__(self):