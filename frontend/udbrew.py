#!/usr/bin/env python3

import os
import sys
import re
import argparse
import subprocess as sbp

version = ["0", "1", "0"]

# Gems list for system.
gems_system_ruby = ["json", "ruby-progressbar", "tty-spinner", "lolcat", "open3"]


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

        log = ""
        p = sbp.Popen(cmd_to_run, shell=True, stdout=sbp.PIPE)
        for line in iter(p.stdout.readline, b""):
            l = line.decode("ascii").strip()
            print(l)
            log += "{}{}".format(l, os.linesep)
        p.stdout.close()
        p.wait()
        return log

    def RunSilent(self, cmd=None):
        if cmd:
            cmd_to_run = cmd
        else:
            cmd_to_run = self.cmd_to_run

        log = ""
        p = sbp.Popen(cmd_to_run, shell=True, stdout=sbp.PIPE)
        for line in iter(p.stdout.readline, b""):
            l = line.decode("ascii").strip()
            log += "{}{}".format(l, os.linesep)
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
        return ".".join([str(_) for _ in self.ver_info])

    def to_list_str(self):
        return [str(_) for _ in self.ver_info]

    def to_list(self):
        return self.ver_info


### DistroPkgMap
###
### Selects pkglist file from given distro info.
###
class DistroPkgMap(GetDistro):
    def __init__(self):
        GetDistro.__init__(self)

        # TODO Populate this part as much as possible...
        #   this part inevitably involves a lot of case study...
        #
        self.distro_to_pkgfile_map = {
            "ubuntu": {
                "Linuxmint_20.1": "ubuntu_20.04_pkgs",
                "Ubuntu_20.04": "ubuntu_20.04_pkgs",
                "elementary_5.1": "ubuntu_18.04_pkgs",
            },
            "fedora": {"rhel_8.3": "rhel_8_pkgs", "fedora_33": "fedora_33_pkgs"},
            "arch": {
                "rolling": "arch_pkgs"
            }
        }

    # Maps distro file with given distro information.
    #
    def GetPackageFileName(self):
        base = self.BaseDistro()
        distro_id = self.ID()
        try:
            ver_split = self.Version().split(".")
            
            if len(ver_split) >= 2:
                ver_major = ver_split[0]
                ver_minor = ver_split[1]
                distro_key = f"{distro_id}_{ver_major}.{ver_minor}"
            else:
                ver_major = self.Version()
                distro_key = f"{distro_id}_{ver_major}"
        except KeyError:
            distro_key='rolling'

        return self.distro_to_pkgfile_map[base][distro_key]


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
        RunCmd.__init__(self, shell_type="bash", verbose=verbose)

        self.base = self.BaseDistro()
        self.pkgs_to_install = self.GetPkgNames()
        # We don't really need whole version. Just major
        if self.base != "arch":
            major_ver = self.Version().split(".")[0]
            self.inst_pkg_func_name = \
                f"install_prereq_{self.ID()}_{major_ver}"
        else:
            self.inst_pkg_func_name = \
                "install_with_pacman"

        self.InstallPackages()

    def InstallPackages(self):
        self.switcher()

    def switcher(self):
        return getattr(self, self.inst_pkg_func_name)()

    # Installation methods...
    #
    def install_with_apt(self):
        self.Run(cmd="sudo -H apt-get -y update")
        self.Run(cmd="sudo -H apt-get -y upgrade")
        self.Run(cmd=f"sudo -H apt-get -y install {self.pkgs_to_instll}")

    def install_prereq_ubuntu_20_04(self):
        self.install_with_apt()

    def install_prereq_ubuntu_18_04(self):
        self.install_with_apt()

    def install_prereq_linuxmint_20(self):
        self.install_prereq_ubuntu_20_04()

    def install_prereq_elementary_5(self):
        self.install_prereq_ubuntu_18_04()

    def install_with_dnf(self):
        self.Run("sudo -H dnf -y update")
        self.Run(f"sudo -H dnf -y install {' '.join(self.pkgs_to_install)}")

    def install_prereq_rhel_8(self):
        print("Installing Prereq. packages for RHEL8")
        self.Run("sudo -H dnf -y update")
        self.Run("sudo -H dnf -y install dnf-plugins-core")
        self.Run(
            'sudo -H subscription-manager repos --enable "codeready-builder-for-rhel-8-$(arch)-rpms"'
        )
        self.Run(
            "sudo -H dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
        )
        self.install_with_dnf()

    def install_with_zypper(self):
        print("Installing with zypper")
        self.Run("sudo -H zypper refresh")
        self.Run("sudo -H zypper update")
        self.Run(f"sudo -H zypper install {' '.join(self.pkgs_to_install)}")

    def install_prereq_openSUSE_15(self):
        self.Run("sudo -H zypper install --type pattern devel_basis")
        self.Run("sudo -H zypper install --type pattern devel_C_C++")
        self.install_with_zypper()

    def install_with_pacman(self):
        print("Syncing with Pacman!")
        self.Run(f"sudo -H pacman -Syyu --noconfirm {' '.join(self.pkgs_to_install)}")

        

class InstallSystemRubyGems(RunCmd):
    def __init__(self, system_ruby="/usr/bin/ruby"):
        RunCmd.__init__(self, verbose=True)
        ruby_ver_str = self.RunSilent(cmd="{} --version".format(system_ruby))
        self.system_ruby_ver = Version(ruby_ver_str.split(" ")[1].split("p")[0])
        self.new_ruby_ver = Version("2.7.0")
        self.system_gem = system_ruby.replace("ruby", "gem")

        # Some gems cannot be installed on old version of ruby
        self.gems_to_install_ver = {}
        if self.system_ruby_ver >= self.new_ruby_ver:
            self.gems_to_install = gems_system_ruby
        else:
            self.gems_to_install = gems_system_ruby
            self.gems_to_install.remove("open3")
            self.gems_to_install_ver["open3"] = "0.1.0"

        self.install_system_ruby_gems()

    def install_system_ruby_gems(self):
        self.Run(
            "sudo -H {} install {}".format(
                self.system_gem, " ".join(self.gems_to_install)
            )
        )
        if len(list(self.gems_to_install_ver.keys())) > 0:
            gems = list(self.gems_to_install_ver.keys())
            vers = [self.gems_to_install_ver[_] for _ in gems]
            for gem, ver in zip(gems, vers):
                self.Run(
                    "sudo -H {} install {} -v {}".format(self.system_gem, gem, ver)
                )


class UDSBrew(object):
    def __init__(self, args):

        self.args = args
        self.mode = ""

        self.mode = "None"
        self.parse_args()

        if self.p_args.prerequisite:
            self.InstallPrerequisiteStuffs()

    def InstallPrerequisiteStuffs(self):
        InstallPrereqPkgs()
        InstallSystemRubyGems()
        sys.exit(0)

    def parse_args(self):
        # InstallPrereqPkgs()
        # InstallSystemRubyGems()
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
            "-pr",
            "--prerequisite",
            action="store_true",
            default=False,
            help="Installs prerequisite packages depending on system's Linux distribution.",
        )
        p.add_argument(
            "-v",
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

        if len(self.args) > 1:
            self.p_args = p.parse_args(self.args[1:])
        else:
            p.print_help()
            sys.exit(1)

    ### Help file
    def show_help(self):
        print("<Put help message here>")
        sys.exit(0)

    ### Show version
    def show_version(self):
        print(f"unix_dev_setup {'.'.join(version)}")
        sys.exit(0)


### Calling main function ###
if __name__ == "__main__":
    UDSBrew(sys.argv)
