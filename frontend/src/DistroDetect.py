#!/usr/bin/env python3

# Contains Linux distro (or other OS, perhaps) detection part.

import os

### Get distro from /etc/os-release ###
class GetDistro(object):
    def __init__(self, release_info="/etc/os-release"):
        if not os.path.exists(release_info):
            raise ValueError("Ouch, we need {}!!".format(release_info))

        with open(release_info, "r") as fp:
            rinfo_str = fp.read()

        self.rel_data = {}
        for ln in rinfo_str.split(os.linesep):
            if not ln:
                continue
            label, item = ln.split("=")
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
                "linuxmint_20.3": "ubuntu_20.04_pkgs",
                "linuxmint_20.2": "ubuntu_20.04_pkgs",
                "linuxmint_20.1": "ubuntu_20.04_pkgs",
                "elementary_5.1": "ubuntu_18.04_pkgs",
                "elementary_6.1": "ubuntu_20.04_pkgs",
                "hamonikr_4.0": "ubuntu_20.04_pkgs",
                "pop_20.04": "ubuntu_20.04_pkgs",
                "pop_20.10": "ubuntu_20.10_pkgs",
                "pop_21.04": "ubuntu_21.04_pkgs",
                "pop_21.10": "ubuntu_21.10_pkgs",
                "pop_22.04": "ubuntu_22.04_pkgs"
            },
            "debian": {
                "ubuntu_22.04": "ubuntu_22.04_pkgs",
                "ubuntu_21.10": "ubuntu_21.10_pkgs",
                "ubuntu_21.04": "ubuntu_21.04_pkgs",
                "ubuntu_20.04": "ubuntu_20.04_pkgs",
                "ubuntu_20.10": "ubuntu_20.10_pkgs",
                "debian_10": "debian_10_pkgs",
            },
            "suse": {
                "opensuse-leap_15.2": "opensuse_15_pkgs",
            },
            "rhel": {
                "centos_7": "rhel_7_pkgs",
                "centos_8": "rhel_8_pkgs",
                "centos_9": "rhel_9_pkgs",
                "almalinux_8.3": "rhel_8_pkgs",
                "almalinux_8.4": "rhel_8_pkgs",
                "almalinux_8.5": "rhel_8_pkgs",
                "almalinux_8.6": "rhel_8_pkgs",
                "almalinux_9.1": "rhel_9_pkgs",
                "rocky_8.3": "rhel_8_pkgs",
                "rocky_8.4": "rhel_8_pkgs",
                "rocky_8.5": "rhel_8_pkgs",
                "rocky_8.6": "rhel_8_pkgs",
                "rocky_9.3": "rhel_9_pkgs",
                "rocky_9.4": "rhel_9_pkgs",
            },
            "fedora": {
                "rhel_9": "rhel_9_pkgs",
                "rhel_8.3": "rhel_8_pkgs",
                "fedora_33": "fedora_33_pkgs",
                "fedora_34": "fedora_34_pkgs",
                "fedora_35": "fedora_35_pkgs",
                "fedora_36": "fedora_36_pkgs",
                "fedora_37": "fedora_37_pkgs",
            },
            "arch": {"rolling": "arch_pkgs"},
            "solus": {
              "solus_4.2": "solus_42_pkgs"
            }
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
            int(ver_split[0])
            if len(ver_split) >= 2:
                ver_major = ver_split[0]
                ver_minor = ver_split[1]
                distro_key = f"{distro_id}_{ver_major}.{ver_minor}"
            else:
                ver_major = ver_split[0]
                distro_key = f"{distro_id}_{ver_major}"
        except ValueError:
            distro_key = "rolling"

        pkg_inst_list = None
        try:
            pkg_inst_list = self.distro_to_pkgfile_map[base][distro_key]
        except KeyError:
            print('{} seems unidentifiable!'.format(distro_key))
            print('Selecting somewhat similar distro...')
            pkg_inst_list = sorted(self.distro_to_pkgfile_map[base].keys())[-1]

        return pkg_inst_list


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
