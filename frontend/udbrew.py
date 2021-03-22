#!/usr/bin/env python3

import os
import sys
import re
import argparse
import subprocess as sbp

# Gems list for system.
gems_system_ruby = [
    'json',
    'ruby-progressbar',
    'tty-spinner',
    'lolcat',
    'open3'
]

### Run Console (Bash.. currently...) ###
class RunCmd(object):
    def __init__(self, shell_type="bash", verbose=False):
        # At this moment, just bash is supported! Let's see if it works out!
        self.shell_type = shell_type
        self.verbose = verbose

    def Run(self, cmd="", env=""):
        if not cmd:
            return 0

        if not env:
            self.cmd_to_run = cmd
        else:
            self.cmd_to_run = "{} {}".format(env, cmd)

        if self.verbose:
            result_log = self.RunVerbose()
        else:
            result_log = self.RunSilent()

        return result_log

    def RunVerbose(self, cmd=None):
        if cmd:
            cmd_to_run = cmd
        else:
            cmd_to_run = self.cmd_to_run

        log = ''
        p = sbp.Popen(cmd_to_run, shell=True, stdout=sbp.PIPE)
        for line in iter(p.stdout.readline, b''):
            l = line.decode('ascii').strip()
            print(l)
            log += '{}{}'.format(l, os.linesep)
        p.stdout.close()
        p.wait()
        return log


    def RunSilent(self, cmd=None):
        if cmd:
            cmd_to_run = cmd
        else:
            cmd_to_run = self.cmd_to_run

        log = ''
        p = sbp.Popen(cmd_to_run, shell=True, stdout=sbp.PIPE)
        for line in iter(p.stdout.readline, b''):
            l = line.decode('ascii').strip()
            log += '{}{}'.format(l, os.linesep)
        p.stdout.close()
        p.wait()
        return log


### Get distro crom /etc/os-release ###
class GetDistro(object):
    def __init__(self, release_info="/etc/os-release"):
        if not os.path.exists(release_info):
            raise ValueError("Ouch, we need {}!!".format(release_info))

        with open(release_info, "r") as fp:
            rinfo_str = fp.read()

        self.rel_data = {}
        for l in rinfo_str.split(os.linesep):
            if not l:
                continue
            label, item = l.split("=")
            self.rel_data[label] = item.replace('"', "")

    def __getitem__(self, info_key):
        return self.rel_data[info_key]

    def Name(self):
        return self.rel_data["NAME"]

    def ID(self):
        return self.rel_data["ID"]

    def Version(self):
        return self.rel_data["VERSION_ID"]

    def BaseDistro(self):
        return self.rel_data["ID_LIKE"]


### Version Parsor ###
class Version(object):
    def __init__(self, ver_info):
        self.ver_info = [0]
        if isinstance(ver_info, str):
            self.init_str(ver_info)
        elif isinstance(ver_info, list):
            self.init_list(ver_info)

    def init_str(self, ver_info):
        self.ver_info = self.split_num_alpha(ver_info.split("."))

    def init_list(self, ver_info):
        self.ver_info = self.split_num_alpha(ver_info)

    # Stupid but needed since some programmers use version number with
    # alphabets such as 23b, 1.11.3a, etc.
    @staticmethod
    def split_num_alpha(ary):
        insert_list = []
        for i, _ in enumerate(ary):
            # knocking out v12.13 case
            if isinstance(_, str) and _[0].lower() == "v":
                ary[i] = _[1:]

            try:
                ary[i] = int(_)
            except ValueError:
                splitted = re.findall(r"[^\W\d_]+|\d+", _)
                for s_i, s in enumerate(splitted):
                    if s.isnumeric():
                        splitted[s_i] = int(s)
                insert_list.append((i, splitted))

        offset = 0
        while insert_list:
            sp = insert_list.pop(0)
            ary[sp[0] + offset] = sp[1][0]
            ary = ary[: sp[0] + 1 + offset] + sp[1][1:] + ary[sp[0] + 1 + offset :]
            offset += len(sp) - 1
        return ary

    def __eq__(self, other):
        return self.ver_info == other.ver_info

    def __ne__(self, other):
        return self.ver_info != other.ver_info

    def __lt__(self, other):
        return self.ver_info < other.ver_info

    def __le__(self, other):
        return self.ver_info <= other.ver_info

    def __gt__(self, other):
        return self.ver_info > other.ver_info

    def __ge__(self, other):
        return self.ver_info >= other.ver_info

    def to_str(self):
        return '.'.join([ str(_) for _ in self.ver_info ])

    def to_list_str(self):
        return [ str(_) for _ in self.ver_info ]

    def to_list(self):
        return self.ver_info

### DistroPkgMap
###
### Selects pkglist file from given distro info.
###
class DistroPkgMap(GetDistro):
    def __init__(self):
        GetDistro.__init__(self)

    # Maps distro file with given distro information.
    #
    # TODO This is crappy preliminary code. Must re-write.
    #
    def GetPackageFileName(self):

        if self.BaseDistro() == "ubuntu":
            if self.Name() == "Linux Mint":
                return "ubuntu_pkgs"
            elif self.Name() == "elementary OS":
                return "ubuntu_18.04_pkgs"

        elif self.BaseDistro() == "fedora":
            if self.Name() == "Red Hat Enterprise Linux":
                return "rhel_pkgs"
            else:
                return "fedora_pkgs"

        elif self.BaseDistro() == "arch":
            return "arch_pkgs"


### GetPackages ###
###
### Finds out the distro and version and fetches list of packages to
### install via package manager.
###
class GetPackages(DistroPkgMap):
    def __init__(self):
        DistroPkgMap.__init__(self)

        this_dir = os.path.realpath(__file__)
        data_dir = os.path.realpath(
            os.path.join(os.path.dirname(this_dir), "..", "data")
        )
        pkg_list_data_fname = self.GetPackageFileName()

        self.pkg_list_file = os.path.join(data_dir, pkg_list_data_fname)
        self.pkg_list = []

    def GetPkgNames(self):
        if not os.path.exists(self.pkg_list_file):
            raise FileNotFoundError(
                "Oh crap, {} is not found!".format(self.pkg_list_file)
            )

        with open(self.pkg_list_file, "r") as fp:
            pl = fp.readlines()
            self.pkg_list = [_.strip() for _ in pl]

        return self.pkg_list


### InstallPkgs ###
###
### Actually installs packages using proper package manager.
###
class InstallPrereqPkgs(GetPackages, RunCmd):
    def __init__(self, verbose=True):
        GetPackages.__init__(self)
        RunCmd.__init__(self, shell_type='bash', verbose=verbose)

        self.base = self.BaseDistro()
        self.pkgs_to_install = self.GetPkgNames()
        self.inst_pkg_f_name = "install_prereq_{}_{}".format(
            self.ID(), self.Version().replace(".", "_")
        )

        self.InstallPackages()

    def InstallPackages(self):
        self.switcher()

    def switcher(self):
        return getattr(self, self.inst_pkg_f_name)()

    # Installation methods...
    def install_prereq_ubuntu_20_04(self):
        self.Run(cmd='sudo -H apt-get -y update')
        self.Run(cmd='sudo apt-get -y upgrade')
        self.Run(cmd='sudo apt-get -y install {}'.format(' '.join(self.pkgs_to_install)))

    def install_prereq_linuxmint_20_1(self):
        self.install_prereq_ubuntu_20_04()

    # pkgs=$( array_to_string "${Ubuntu_packages[@]}")
    # gems=$( array_to_string "${Ruby_gems[@]}")
    # sudo -H apt-get -y update && sudo apt-get -y upgrade
    # sudo -H apt-get -y install $pkgs
    # sudo -H /usr/bin/gem install $gems

    def install_with_dnf(self):
        print("Installing with dnf")

    def install_prereq_rhel_8_3(self):
        print("Installing Prereq. packages for RHEL8.3")

    def install_with_zypper(self):
        print("Installing with zypper")

    def install_with_pacman(self):
        print("Syncing with Pacman!")


class InstallSystemRubyGems(RunCmd):
    def __init__(self, system_ruby='/usr/bin/ruby'):
        RunCmd.__init__(self, verbose=True)
        ruby_ver_str = self.RunSilent(cmd='{} --version'.format(system_ruby))
        self.system_ruby_ver = Version(ruby_ver_str.split(' ')[1].split('p')[0])
        self.new_ruby_ver = Version('2.7.0')
        self.system_gem = system_ruby.replace('ruby','gem')

        # Some gems cannot be installed on old version of ruby
        self.gems_to_install_ver = {}
        if self.system_ruby_ver >= self.new_ruby_ver:
            self.gems_to_install = gems_system_ruby
        else:
            self.gems_to_install = gems_system_ruby
            self.gems_to_install.remove('open3')
            self.gems_to_install_ver['open3'] = '0.1.0'

        self.install_system_ruby_gems()

    def install_system_ruby_gems(self):
        self.Run('sudo -H {} install {}'.format(
            self.system_gem, ' '.join(self.gems_to_install)))
        if len(list(self.gems_to_install_ver.keys())) > 0:
            gems = list(self.gems_to_install_ver.keys())
            vers = [ self.gems_to_install_ver[_] for _ in gems ]
            for gem, ver in zip(gems, vers):
                self.Run('sudo -H {} install {} -v {}'.format(
                    self.system_gem, gem, ver))


class UDSBrew(object):
    def __init__(self, args):
        InstallPrereqPkgs()
        InstallSystemRubyGems()

    ### Help file
    def show_help(self):
        print("<Put help message here>")


### Calling main function ###
if __name__ == "__main__":
    UDSBrew(sys.argv)
