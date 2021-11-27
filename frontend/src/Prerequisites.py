#!/usr/bin/env python3

# Handles prerequisite package (using system's package manager) installation

from .DistroDetect import GetPackages
from .Utils import RunCmd

import os
import re
import subprocess

new_ruby_ver='2.7.4'
new_git_ver='2.33.0'

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

        self.prefix = self.set_prefix()

        self.InstallPackages()

    def need_sudo(self):
        return not os.access(os.environ.get("HOMEBREW"), os.W_OK)

    def InstallPackages(self):
        self.switcher()
        
    def GetCPUCount(self):
        try:
            m = re.search(r'(?m)^Cpus_allowed:\s*(.*)$',
                              open('/proc/self/status').read())
            if m:
                res = bin(int(m.group(1).replace(',', ''), 16)).count('1')
                if res > 0:
                    return res
        except IOError:
            pass

        # Python 2.6+
        try:
            import multiprocessing
            return multiprocessing.cpu_count()
        except (ImportError, NotImplementedError):
            pass

        # https://github.com/giampaolo/psutil
        try:
            import psutil
            return psutil.cpu_count()   # psutil.NUM_CPUS on old versions
        except (ImportError, AttributeError):
            pass

        # POSIX
        try:
            res = int(os.sysconf('SC_NPROCESSORS_ONLN'))

            if res > 0:
                return res
        except (AttributeError, ValueError):
            pass

        # Windows
        try:
            res = int(os.environ['NUMBER_OF_PROCESSORS'])

            if res > 0:
                return res
        except (KeyError, ValueError):
            pass

        # jython
        try:
            from java.lang import Runtime
            runtime = Runtime.getRuntime()
            res = runtime.availableProcessors()
            if res > 0:
                return res
        except ImportError:
            pass

        # BSD
        try:
            sysctl = subprocess.Popen(['sysctl', '-n', 'hw.ncpu'],
                                      stdout=subprocess.PIPE)
            scStdout = sysctl.communicate()[0]
            res = int(scStdout)

            if res > 0:
                return res
        except (OSError, ValueError):
            pass

        # Linux
        try:
            res = open('/proc/cpuinfo').read().count('processor\t:')

            if res > 0:
                return res
        except IOError:
            pass

        # Solaris
        try:
            pseudoDevices = os.listdir('/devices/pseudo/')
            res = 0
            for pd in pseudoDevices:
                if re.match(r'^cpuid@[0-9]+$', pd):
                    res += 1

            if res > 0:
                return res
        except OSError:
            pass

        # Other UNIXes (heuristic)
        try:
            try:
                dmesg = open('/var/run/dmesg.boot').read()
            except IOError:
                dmesgProcess = subprocess.Popen(['dmesg'], stdout=subprocess.PIPE)
                dmesg = dmesgProcess.communicate()[0]

            res = 0
            while '\ncpu' + str(res) + ':' in dmesg:
                res += 1

            if res > 0:
                return res
        except OSError:
            pass

        raise Exception('Can not determine number of CPUs on this system')
        

    def set_prefix(self):
        prefix = os.environ.get("HOMEBREW")
        if prefix:
            return prefix
        else:
            return '/usr/local'

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

    def install_prereq_ubuntu_21(self):
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
        
    def install_prereq_pop_20(self):
        self.install_prereq_ubuntu_20()
    
    def install_prereq_pop_21(self):
        self.install_prereq_ubuntu_21()

    def install_prereq_solus_4(self):
        self.install_prereq_solus_4dot2()
        
    def install_prereq_rocky_8(self):
        self.install_prereq_centos_8()

    def install_with_dnf(self):
        self.Run("sudo -H dnf -y update")
        self.Run(f"sudo -H dnf -y install {' '.join(self.pkgs_to_install)}")

    def install_with_yum(self):
        self.Run("sudo -H yum -y update")
        self.Run("sudo -H yum -y install "+' '.join(self.pkgs_to_install) )

    def install_prereq_rhel_8(self):
        # print("Installing Prereq. packages for RHEL8")
        self.Run("sudo -H dnf -y update")
        self.Run("sudo -H dnf -y install dnf-plugins-core")
        self.Run(
            'sudo -H subscription-manager repos --enable "codeready-builder-for-rhel-8-x86_64-rpms"'
        )
        self.Run(
            "sudo -H dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
        )
        self.install_with_dnf()

    def install_prereq_centos_7(self):
        self.Run("sudo -H yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
        self.Run("sudo -H subscription-manager repos –enable \"rhel-*-optional-rpms\" –enable \"rhel-*-extras-rpms\" –enable \"rhel-ha-for-rhel-*-server-rpms\"")
        self.Run("sudo -H yum -y install gcc gcc-c++ make glibc-devel openssl-devel autoconf automake binutils bison flex gettext libtool patch pkgconfig redhat-rpm-config rpm-build rpm-sign ctags elflutils indent patchutils curl libcurl-devel")
        self.install_with_yum()
        self.install_ruby_new()
        self.install_git_new()

    def install_prereq_centos_8(self):
        # print("Installing CentOS repos.")
        self.Run("sudo -H dnf -y install epel-release")
        self.Run("sudo -H dnf config-manager --set-enabled powertools")
        self.Run(
            'sudo -H dnf -y groupinstall "Development Tools" "Additional Development"'
        )
        self.install_with_dnf()

    def install_prereq_centos_9(self):
        # print("Installing CentOS repos.")
        self.Run("sudo -H dnf -y install epel-release")
        self.Run("sudo -H dnf config-manager --set-enabled powertools")
        self.Run(
            'sudo -H dnf -y groupinstall "Development Tools" "Additional Development"'
        )
        self.install_with_dnf()

    def install_prereq_fedora_33(self):
        # print("Installing Fedora packages!!")
        cmds = [
            "sudo -H dnf -y update",
            'sudo -H dnf -y groupinstall "Development Tools" "Additional Development"',
        ]
        self.Run(cmds)
        self.install_with_dnf()

    def install_prereq_almalinux_8(self):
        # print("Almalinux detected! Activating CentOS repo!")
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
        # print("Syncing with Pacman!")
        self.Run(f"sudo -H pacman -Syyu --noconfirm {' '.join(self.pkgs_to_install)}")

    def install_prereq_solus_4dot2(self):
        # print("Installing base packages!!")
        self.Run("sudo -H eopkg up")
        self.Run("sudo -H eopkg install -y -c system.devel")
        self.Run(f"sudo -H eopkg install -y {' '.join(self.pkgs_to_install)}")
    
    def install_ruby_new(self):
        
        ruby_ver_maj_min = '.'.join(new_ruby_ver.split('.')[:2])
        cmd = ' && '.join(
            [
                "rm -rf /tmp/ruby-*.*.*.tar.* /tmp/ruby-*.*.*",
                "cd /tmp",
                "wget https://cache.ruby-lang.org/pub/ruby/{}/ruby-{}.tar.gz".format(ruby_ver_maj_min, new_ruby_ver),
                "tar xf ./ruby-{}.tar.gz".format(new_ruby_ver),
                "cd ./ruby-{}".format(new_ruby_ver),
                "./configure --prefix={}".format(self.prefix),
                "make -j {}".format(self.GetCPUCount()),
            ] )

        if self.need_sudo():
            cmd += "&& sudo -H make install"
        else:
            cmd += "&& make install"

        self.Run(cmd)
    
    def install_git_new(self):
        cmd = ' && '.join(
            [
                "rm -rf /tmp/git-*.*.*.tar.* /tmp/git-*.*.*",
                "cd /tmp",
                f"wget \"https://www.kernel.org/pub/software/scm/git/git-{new_git_ver}.tar.xz\" -O \"/tmp/git-{new_git_ver}.tar.xz\"",
                "tar xf ./git-{}.tar.xz".format(new_git_ver),
                "cd ./git-{}".format(new_git_ver),
                "make configure",
                "./configure --prefix={}".format(self.prefix),
                "make -j {}".format(self.GetCPUCount())
            ] )

        if self.need_sudo():
            cmd += "&& sudo -H make install"
        else:
            cmd += "&& make install"

        self.Run(cmd)
    
