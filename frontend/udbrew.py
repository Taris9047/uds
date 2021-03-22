#!/usr/bin/env python3

import os
import sys
import re
import subprocess as sbp

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


### DistroPkgMap
###
### Selects pkglist file from given distro info.
###
class DistroPkgMap(GetDistro):
    def __init__(self):
        super().__init__()

    # Maps distro file with given distro information.
    #
    # TODO This is crappy preliminary code. Must re-write.
    #
    def GetPackageFileName(self):

        if self.BaseDistro() == "ubuntu":
            if self.Name() == "Linuxmint":
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
        super().__init__()
        this_dir = os.path.realpath(__file__)
        data_dir = os.path.realpath(
            os.path.join(os.path.dirname(this_dir), "..", "data")
        )
        pkg_list_data_fname = self.GetPackageFileName()

        self.pkg_list_file = os.path.join(data_dir, pkg_list_data_fname)
        self.pkg_list = []

    def GetPkgNames(self):
        if not os.path.exists(self.pkg_list_file):
            raise FileNotExistError(
                "Oh crap, {} is not found!".format(self.pkg_list_file)
            )

        with open(self.pkg_list_file, "r") as fp:
            self.pkg_list = fp.readlines()

        return self.pkg_list


### InstallPkgs ###
###
### Actually installs packages using proper package manager.
###
class InstallPrereqPkgs(GetPackages):
    def __init__(self):
        super().__init__()

        self.base = self.BaseDistro()
        self.pkgs_to_install = self.GetPkgNames()

        self.distro_pkgman_map = {
            "ubuntu": "apt",
            "fedora": "dnf",
            "rhel": "dnf",
            "opensuse": "zypper",
            "arch": "pacman",
        }

        self.InstallPackages()

    def InstallPackages(self):
        self.switcher()

    def switcher(self):
        return getattr(
            self, "install_with_{}".format(self.distro_pkgman_map[self.base])
        )()

    # TODO Implement those dummys into greatness!!
    def install_with_apt(self):
        print("Installing with apt-get")

    # pkgs=$( array_to_string "${Ubuntu_packages[@]}")
    # gems=$( array_to_string "${Ruby_gems[@]}")
    # sudo -H apt-get -y update && sudo apt-get -y upgrade
    # sudo -H apt-get -y install $pkgs
    # sudo -H /usr/bin/gem install $gems

    def install_with_dnf(self):
        print("Installing with dnf")

    def install_with_zypper(self):
        print("Installing with zypper")

    def install_with_pacman(self):
        print("Syncing with Pacman!")


### Help file
def show_help():
    print("<Put help message here>")


### The Main Function ###
def main(ARGV):

    # if not len(ARGV) > 2:
    #     show_help()

    InstallPrereqPkgs()


### Calling main function ###
if __name__ == "__main__":
    main(sys.argv)
