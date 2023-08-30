#!/usr/bin/env python3

"""
	Installs Nanum Fonts...

    from Naver!
	
"""

import os
import zipfile
import shutil

from .Utils import RunCmd
from .Utils import mkdirp

NanumFontURL = "https://github.com/Taris9047/taris-personal-settings/releases/download/Nanum/NanumFonts.zip"

class NanumFonts(RunCmd):

    def __init__(self):

        RunCmd.__init__(self, shell_type="bash", verbose=True)

        self.HomeDir = os.environ.get('HOME')
        self.font_install_dir = \
            os.path.join(self.HomeDir, '.local', 'fonts', 'NanumFonts')

        if os.path.isdir(self.font_install_dir):
            shutil.rmtree(self.font_install_dir)
        mkdirp(self.font_install_dir)

        self.temp_dir = os.path.join('/','tmp','.nanum_temp')
        if os.path.isdir(self.temp_dir):
            shutil.rmtree(self.temp_dir)
        mkdirp(self.temp_dir)

        self.downloaded_nanumfont_archive = ''

        self.DownloadNanumFonts()
        self.InstallNanumFonts()            

    def DownloadNanumFonts(self):
        self.downloaded_nanumfont_archive = \
            os.path.join(self.temp_dir, 'NanumFonts.zip')

        self.Run("wget {} -O {}".format(
            NanumFontURL, self.downloaded_nanumfont_archive
        ))

    def InstallNanumFonts(self):

        if os.path.isfile(self.downloaded_nanumfont_archive):
            with zipfile.ZipFile(self.downloaded_nanumfont_archive) as zip_ref:
                zip_ref.extractall(self.font_install_dir)
        else:
            self.DownloadNanumFonts()

        self.Run("fc-cache -fv")



