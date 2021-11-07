#!/usr/bin/env python3

# Handles Ruby installation part

from .Utils import RunCmd, Version

import os


# Gems list for system.
gems_system_ruby = [
    "json", "ruby-progressbar", "tty-spinner", "lolcat", "open3"
]


class InstallSystemRubyGems(RunCmd):
    def __init__(self, system_ruby="/usr/bin/ruby"):
        RunCmd.__init__(self, verbose=True)
        
        self.need_sudo = True
        # Trying to probe ruby at $HOME/.local
        homebrew_ruby = \
            os.path.isfile(os.path.join(os.environ.get("HOMEBREW"),'bin','ruby'))
        if homebrew_ruby:
            system_ruby=\
                os.path.realpath(os.path.join(os.environ.get("HOMEBREW"),'bin','ruby'))
            self.need_sudo = not os.access(os.environ.get("HOMEBREW"), os.W_OK)
        
        ruby_ver_str = self.RunSilent(cmd="{} --version".format(system_ruby))
        print(ruby_ver_str)
        self.system_ruby_ver = \
            Version(ruby_ver_str.split(" ")[1].split("p")[0])
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

