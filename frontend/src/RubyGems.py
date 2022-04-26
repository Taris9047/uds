#!/usr/bin/env python3

# Handles Ruby installation part

from .Utils import RunCmd, Version

# from distutils.spawn import find_executable
from shutil import which
import os

# Default homebrew directory
def_homebrew_dir = '~/.local'

# Gems list for system.
gems_system_ruby = [
    "json", "ruby-progressbar", "tty-spinner", "lolcat", "open3"
]


class InstallSystemRubyGems(RunCmd):
    def __init__(self, system_ruby="/usr/bin/ruby"):
        RunCmd.__init__(self, verbose=True)

        self.need_sudo = True
        # Trying to probe ruby at $HOME/.local
        if os.environ.get('HOMEBREW') is not None:
            homebrew_ruby = \
                os.path.isfile(os.path.join(os.environ.get("HOMEBREW"),'bin','ruby'))
            if os.path.isfile(homebrew_ruby):
                system_ruby=\
                    os.path.realpath(os.path.join(os.environ.get("HOMEBREW"),'bin','ruby'))
            else:
                # system_ruby = find_executable('ruby')
                system_ruby = which('ruby')

        else:
            # homebrew_ruby = find_executable('ruby')
            homebrew_ruby = which('ruby')
            # system_ruby = find_executable('ruby')
            system_ruby = which('ruby')

        if os.environ.get("HOMEBREW") is not None:
            self.need_sudo = not os.access(os.environ.get("HOMEBREW"), os.W_OK)
        else:
            self.need_sudo = not os.access(def_homebrew_dir, os.W_OK)

        ruby_ver_str = self.RunSilent(cmd="{} --version".format(system_ruby))
        self.system_ruby_ver = \
            Version(ruby_ver_str[0].split(" ")[1].split("p")[0])
        self.new_ruby_ver = Version("2.7.0")
        self.system_gem = system_ruby.replace("ruby", "gem")

        # Some gems cannot be installed on old version of ruby
        self.gems_to_install_ver = {}
        if self.system_ruby_ver >= self.new_ruby_ver:
            self.gems_to_install = gems_system_ruby
        else:
            if self.system_ruby_ver < Version("2.3.0"):
                gems_system_ruby.remove('json')
            self.gems_to_install = gems_system_ruby
            self.gems_to_install.remove("open3")
            self.gems_to_install_ver["open3"] = "0.1.0"

        self.install_system_ruby_gems()

    def install_system_ruby_gems(self):
        self.Run(f"sudo -H {self.system_gem} install {' '.join(self.gems_to_install)}")
        if len(list(self.gems_to_install_ver.keys())) > 0:
            gems = list(self.gems_to_install_ver.keys())
            vers = [self.gems_to_install_ver[_] for _ in gems]
            for gem, ver in zip(gems, vers):
                if self.need_sudo:
                    self.Run(f"sudo -H {self.system_gem} install {gem} -v {ver}")
                else:
                    self.Run(f"{self.system_gem} install {gem} -v {ver}")

