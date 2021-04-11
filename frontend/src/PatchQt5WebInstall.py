#!/usr/bin/env python3

# Patches qt5 web install pkgconfig files.

import os
import sys
import glob

class PatchQt5WebInstall(object):
    def __init__(self, qt5version='5.12.2', qt5path='#HOME#/.Qt/#qt5_version#/gcc_64'):

        self.qt5version = qt5version
        self.qt5path = \
            qt5path.replace('#qt5_version#', qt5version).replace('#HOME#', os.path.expandvars('$HOME'))

        if not os.path.isdir(self.qt5path):
            print("Oh, Qt5 Web install directory can't be found!")
            print(f"Maybe other place than?: {self.qt5path}")
            sys.exit(-1)

        self.not_good_str = '/home/qt/work/install'
        self.good_str = f"{self.qt5path}"

        self.do_patch()

    def do_patch(self):
        self.qt5_web_pkgconfig_path = os.path.join(self.qt5path, 'lib', 'pkgconfig')
        glob_wildcard = os.path.join(self.qt5_web_pkgconfig_path, '*.pc')
        pc_file_list = glob.glob(f"{glob_wildcard}")

        # Doing patch!
        for pc_file in pc_file_list:
            self.inplace_change(pc_file, self.not_good_str, self.good_str)

    @staticmethod
    def inplace_change(fname, old_str, new_str):
        with open(fname) as fp:
            s = fp.read()
            if old_str not in s:
                print(f"Given string '{old_str}' was not found in {fname}!!")
                return

        with open(fname, 'w') as fp:
            s = s.replace(old_str, new_str)
            f.write(s)

