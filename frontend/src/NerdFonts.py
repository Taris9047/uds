#!/usr/bin/env python3

"""
	Installs some Nerd Fonts
	
"""

import os
import zipfile
import shutil

from .Utils import RunCmd
from .Utils import mkdirp


class NerdFonts(RunCmd):
	
	"""
		Initializer.
		
	"""
	
	NerdFontsToInstall = []
	DefaultFontPath = ''
	NerdFontVersion = 'v3.0.2'
	
	def __init__(self, NerdFontNames='', verbose=True, Nuke=False):
		RunCmd.__init__(self, shell_type="bash", verbose=verbose)
		
	
		if not NerdFontNames:
			self.NerdFontsToInstall.append('FiraCode')
		else:
			self.NerdFontsToInstall = \
				[_.replace(' ','') for _ in NerdFontNames]

		self.HomeDir = os.environ.get('HOME')
		self.DefaultFontPath = \
			os.path.join(self.HomeDir,
						'.local', 'share',
						 'fonts', 'NerdFonts')

		if not os.path.isdir(self.DefaultFontPath):
			mkdirp(self.DefaultFontPath)
			
		self.TempDownloadDir = './.nf_tmp'
		if not os.path.isdir(self.TempDownloadDir):
			mkdirp(self.TempDownloadDir)

		if Nuke:
			shutil.rmtree(self.DefaultFontPath)
			shutil.rmtree(self.TempDownloadDir)
			return
		
		self.InstallNerdFonts()
		
		self.Cleanup()
		
	def InstallNerdFonts(self):
		
		if not os.path.isdir(self.DefaultFontPath):
			raise "We need to make a directory for Nerd Fonts."
			
			
		NF_links = []
		
		# Now generating the font download link from 
		# the Nerd Font github page.
		#   https://www.nerdfonts.com/font-downloads
		#
		for fnt in self.NerdFontsToInstall:
			fnt_link = \
				"https://github.com/ryanoasis/"\
				"nerd-fonts/releases/download/{}/{}.zip"\
				.format(self.NerdFontVersion, fnt)
			
			self.Run(
				"wget -O {} {}".format(
				os.path.join(self.TempDownloadDir, "{}.zip".format(fnt)), 
					fnt_link))
			fnt_dir = os.path.join(self.DefaultFontPath, fnt)
			if os.path.isdir(fnt_dir):
				shutil.rmtree(fnt_dir)
			mkdirp(fnt_dir)
			
			with zipfile.ZipFile(
				os.path.join(
					self.TempDownloadDir, 
					"{}.zip".format(fnt))) as zip_ref:
				zip_ref.extractall(fnt_dir)
		
		self.Run("fc-cache -fv")
	
	def Cleanup(self):
		shutil.rmtree(self.TempDownloadDir)	
