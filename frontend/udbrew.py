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
            l = line.decode("utf-8").strip()
            sys.stdout.buffer.write(line)
            sys.stdout.flush()
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
            l = line.decode("utf-8").strip()
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
        try:
            return self.rel_data["NAME"]
        except KeyError:
            return ""

    def ID(self):
        try:
            return self.rel_data["ID"]
        except KeyError:
            return ""

    def Version(self):
        try:
            return self.rel_data["VERSION_ID"]
        except KeyError:
            return ""

    def BaseDistro(self):
        try:
            return self.rel_data["ID_LIKE"]
        except KeyError:
            return self.ID()


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
                "linuxmint_20.1": "ubuntu_20.04_pkgs",
                "elementary_5.1": "ubuntu_18.04_pkgs",
            },
            "debian": {
                "ubuntu_20.04": "ubuntu_20.04_pkgs",
                "ubuntu_20.10": "ubuntu_20.10_pkgs",
                "debian_10": "debian_10_pkgs",
            },
            "suse": {
                "opensuse-leap_15.2": "opensuse_15_pkgs",
            },
            "rhel": {
                "centos_8": "rhel_8_pkgs",
                "almalinux_8.3": "rhel_8_pkgs",
            },
            "fedora": {
                "rhel_8.3": "rhel_8_pkgs",
                "fedora_33": "fedora_33_pkgs",
            },
            "arch": {"rolling": "arch_pkgs"},
        }

    # Maps distro file with given distro information.
    #
    def GetPackageFileName(self):
        base = self.BaseDistro()

        if len(base.split(" ")) > 1:
            base = base.split(" ")[0]

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
            distro_key = "rolling"

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
            self.inst_pkg_func_name = f"install_prereq_{self.ID()}_{major_ver}"
        else:
            self.inst_pkg_func_name = "install_with_pacman"

        self.InstallPackages()

    def InstallPackages(self):
        self.switcher()

    def switcher(self):
        self.inst_pkg_func_name = self.inst_pkg_func_name.replace("-", "_")
        return getattr(self, self.inst_pkg_func_name)()

    # Installation methods...
    #
    def install_with_apt(self):
        self.Run(cmd="sudo -H apt-get -y update")
        self.Run(cmd="sudo -H apt-get -y upgrade")
        self.Run(cmd=f"sudo -H apt-get -y install {' '.join(self.pkgs_to_install)}")

    def install_prereq_ubuntu_20(self):
        self.install_with_apt()

    def install_prereq_ubuntu_18(self):
        self.install_with_apt()
        
    def install_prereq_debian_10(self):
        self.install_with_apt()

    def install_prereq_linuxmint_20(self):
        self.install_prereq_ubuntu_20()

    def install_prereq_elementary_5(self):
        self.install_prereq_ubuntu_18()

    def install_with_dnf(self):
        self.Run("sudo -H dnf -y update")
        self.Run(f"sudo -H dnf -y install {' '.join(self.pkgs_to_install)}")

    def install_prereq_rhel_8(self):
        print("Installing Prereq. packages for RHEL8")
        self.Run("sudo -H dnf -y update")
        self.Run("sudo -H dnf -y install dnf-plugins-core")
        self.Run(
            'sudo -H subscription-manager repos --enable "codeready-builder-for-rhel-8-x86_64-rpms"'
        )
        self.Run(
            "sudo -H dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
        )
        self.install_with_dnf()

    def install_prereq_centos_8(self):
        print("Installing CentOS repos.")
        self.Run("sudo -H dnf -y install epel-release")
        self.Run("sudo -H dnf config-manager --set-enabled powertools")
        self.Run(
            'sudo -H dnf -y groupinstall "Development Tools" "Additional Development"'
        )
        self.install_with_dnf()

    def install_prereq_almalinux_8(self):
        print("Almalinux detected! Activating CentOS repo!")
        self.install_prereq_centos_8()

    def install_with_zypper(self):
        print("Installing with zypper")
        self.Run("sudo -H zypper refresh")
        self.Run("sudo -H zypper update")
        self.Run(f"sudo -H zypper install {' '.join(self.pkgs_to_install)}")

    def install_prereq_opensuse_leap_15(self):
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


class UDSBrew(RunCmd):
    def __init__(self, args):
        RunCmd.__init__(self, shell_type="bash", verbose=True)

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

        if self.p_args.install is not []:
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
                "-quiet",
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

            for pkg in parsed_inst_args.pkgs_to_install:
                self.Run(f"ruby ./unix_dev_setup {opt_verbose} {opt_sgcc} {pkg}")

            sys.exit(0)

        if self.p_args.uninstall is not []:
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
