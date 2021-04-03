#!/usr/bin/env python3

# Handles prerequisite package (using system's package manager) installation

from .DistroDetect import GetPackages
from .Utils import RunCmd


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

    def install_prereq_hamonikr_4(self):
        self.install_prereq_ubuntu_20()

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

    def install_prereq_fedora_33(self):
        print("Installing Fedora packages!!")
        cmds = [
            "sudo -H dnf -y update",
            'sudo -H dnf -y groupinstall "Development Tools" "Additional Development"',
        ]
        self.Run(cmds)
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
