#!/usr/bin/env python3

import os
import sys
import re


### Get distro crom /etc/os-release ###
class GetDistro(object):
    def __init__(self, release_info='/etc/os-release'):
        if not os.path.exists(release_info):
            raise ValueError("Ouch, we need {}!!".format(release_info))

        with open(release_info, 'r') as fp:
            rinfo_str = fp.read()

        self.rel_data = {}
        for l in rinfo_str.split(os.linesep):
            if not l:
                continue
            label, item = l.split('=')
            self.rel_data[label] = item

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
        self.ver_info = self.split_num_alpha(ver_info.split('.'))
            
    def init_list(self, ver_info):
        self.ver_info = self.split_num_alpha(ver_info)

    # Stupid but needed since some programmers use version number with
    # alphabets such as 23b, 1.11.3a, etc.
    @staticmethod
    def split_num_alpha(ary):
        insert_list = []
        for i, _ in enumerate(ary):
            # knocking out v12.13 case
            if isinstance(_, str) and _[0].lower() == 'v':
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
            ary[sp[0]+offset] = sp[1][0]
            ary = ary[:sp[0]+1+offset]+sp[1][1:]+ary[sp[0]+1+offset:]
            offset += len(sp)-1
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
    GetDistro.__init__()
    def __init__(self):
        self.distro_info = {}
        self.distro_info['Name'] = self.Name()
        self.distro_info['Version'] = self.Version()
        self.distro_info['Base'] = self.BaseDistro()
        
    # Maps distro file with given distro information.
    #
    # TODO This is crappy preliminary code. Must re-write.
    # 
    def GetPackageFileName(self):
        Ubuntu_20_04_based = ["Ubuntu" "Linuxmint"]
        
        if self.distro_info['Base'] == 'ubuntu':
            if self.distro_info['Name'] == 'Linuxmint':
                return 'ubuntu_pkgs'
            elif self.distro_info['Name'] == 'elementary OS':
                return 'ubuntu_18.04_pkgs'
    
        elif self.distro_info['Base'] == 'fedora':
            return 'fedora_pkgs'

        elif self.distro_info['Base'] == 'arch':
            return 'arch_pkgs'
        
### GetPackages ###
###
### Finds out the distro and version and fetches list of packages to
### install via package manager.
###
class GetPackages(DistroPkgMap):
    DistroPkgMap.__init__()
    
    def __init__(self):
        this_dir = os.path.realpath(__file__)
        data_dir = os.path.realpath(os.path.join(os.path.dirname(this_dir), '..', 'data'))

        self.pkg_list_file = \
            os.path.join(data_dir, self.GetPackageFileName())
        self.pkg_list = []
        
    def GetPkgNames(self):
        if not os.path.exists(self.pkg_list_file):
            raise FileNotExistError("Oh crap, {} is not found!".format(self.pkg_list_file))

        with open(self.pkg_list_file, 'r') as fp:
            self.pkg_list = fp.readlines()

        return self.pkg_list

### InstallPkgs ###
###
### Actually installs packages using proper package manager.
###
class InstallPrereqPkgs(GetPackages):
    def __init__(self):
        GetPackages.__init__()

        self.distro_info = GetDistro()
        pkm = GetPackages()
        self.pkgs_to_install = self.GetPkgNames()
        self.base = self.distro_info.BaseDistro()

        self.distro_pkgman_map = {
            'ubuntu': 'apt',
            'fedora': 'dnf',
            'rhel': 'dnf',
            'opensuse': 'zypper',
            'arch': 'pacman'
        }
        
        self.InstallPackages()

    def InstallPackages(self):
        self.switcher()

    def switcher(self):
        return getattr(self, 'install_with_{}'.format(
            self.distro_pkgman_map[self.base]))()
    
    # TODO Implement those dummys into greatness!!
    def install_with_apt(self):
        print("Installing with apt-get")

    def install_with_dnf(self):
        print("Installing with dnf")

    def install_with_zypper(self):
        print("Installing with zypper")

    def install_with_pacman(self):
        print("Syncing with Pacman!")
        
        
### Help file
def show_help():
    print('<Put help message here>')

### The Main Function ###
def main (ARGV):

    if not len(ARGV) > 1:
        self.show_help()

    InstallPrereqPkgs()

### Calling main function ###
if __name__ == "__main__":
    main(sys.argv)