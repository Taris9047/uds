#!/usr/bin/env ruby

# Installs giflib

require 'fileutils'

require_relative '../../utils/utils.rb'
require_relative '../install_stuff.rb'

class InstGiflib < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)
    
    @source_url = SRC_URL[@pkgname]
    @ver_maj_min = "#{SRC_VER[@pkgname].major}.#{SRC_VER[@pkgname].minor}"
    @version = SRC_VER[@pkgname].to_s

    # Setting up compilers
    self.CompilerSet

  end

  def do_install

    dl = Download.new(@source_url, @src_dir)
    # src_tarball_path = dl.GetPath

    fp = FNParser.new(@source_url)
    src_tarball_fname, src_tarball_bname = fp.name
    major, minor, patch = fp.version

    # puts src_tarball_fname, src_tarball_bname, major, minor, patch
    src_extract_folder = File.join(File.realpath(@build_dir), src_tarball_bname)
    @src_build_dir = src_extract_folder

    if Dir.exists?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
      puts "Deleting ... "
      FileUtils.rm_rf(src_extract_folder)
    end

    puts "Extracting"
    self.Run(
      "tar xf "+File.realpath(File.join(@src_dir, src_tarball_fname))+" -C "+@build_dir )

    puts "Installing #{@pkgname}!!"
    install_cmd = [
      "make",
      "PREFIX=\"#{@prefix}\"",
      "install",
    ].join(' ')

    if @need_sudo
      sudo_cmd = 'sudo -H'
    else
      sudo_cmd = ''
    end

    # Ok let's roll!!
    cmds = [
      "cd", src_extract_folder,
      "&&", "make CFLAGS=\"#{@env["CFLAGS"]} -fPIC\" LDFLAGS=\"#{@env["LDFLAGS"]}\" ",
      "&&", sudo_cmd, install_cmd,
    ]
    self.RunInstall( env: @env, cmd: cmds.join(" ") )
    self.WriteInfo
  end

end # class InstGiflib
