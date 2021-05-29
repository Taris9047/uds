#!/usr/bin/env ruby

# this will handle ngspice

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

require 'fileutils'

class InstNgspice < InstallStuff

  def initialize(args)

    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]

    # mpich build options
    @conf_options = [
      "--enable-xspice",
      "--enable-cider",
      "--enable-capbypass",
      "--enable-predictor",
      "--enable-newtrunc",
      "--enable-sense2",
      "--enable-openmp"
    ]

    # Setting up compilers
    self.CompilerSet

  end

  def do_install

    dl = Download.new(@source_url, @src_dir)
    src_tarball_path = dl.GetPath

    fp = FNParser.new(@source_url)
    src_tarball_fname, src_tarball_bname = fp.name
    major, minor, patch = fp.version

    # puts src_tarball_fname, src_tarball_bname, major, minor, patch
    src_extract_folder = File.join(File.realpath(@build_dir), src_tarball_bname)
    @src_build_dir = File.join(File.realpath(@build_dir), src_tarball_bname+'-build')

    if Dir.exists?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
    else
      puts "Extracting"
      self.Run( "tar xf "+File.realpath(File.join(@src_dir, src_tarball_fname))+" -C "+@build_dir )
    end

    if Dir.exists?(@src_build_dir)
      puts "Build folder found!! Removing it for 'pure' experience!!"
      self.Run( "rm -rfv "+@src_build_dir )
    else
      puts "Ok, let's make a build folder"
    end
    self.Run( "mkdir -p "+@src_build_dir )

    opts = ["--prefix="+@prefix]+@conf_options

    if @need_sudo
      inst_cmd = "sudo make install"
      mod_sudo = "sudo -H"
    else
      inst_cmd = "make install"
      mod_sudo = ""
    end

    # Ok let's roll!!
    cmds = [
      "cd", @src_build_dir, "&&",
      src_extract_folder+"/configure",
      opts.join(" "), "&&",
      "nice make -j", @Processors.to_s, "&&",
      inst_cmd
    ]

    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( env: @env, cmd: cmds.join(" ") )
    self.WriteInfo

    # To avoid confusion... let's move config.h to somewhere else.
    # FileUtils.mv File.join(@prefix, 'include', 'config.h') File.join(@prefix, 'include', 'ngspice', 'config.h')

    puts "This is bare bones ngspice! Put in SPICE libraries to #{@prefix}"
  end

end # class InstNgspice
