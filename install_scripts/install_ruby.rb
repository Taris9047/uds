#!/usr/bin/env ruby

# this will handle Ruby

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

$gems_to_install = [
    "rsense",
    "rails",
    "rake",
    "bundler",
    "open3",
    "json",
    "hjson",
    "ruby-progressbar",
    "tty-spinner",
  ]

class InstRuby < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]

    # Ruby modules to install
    @ruby_gems = $gems_to_install

    # Ruby build options
    @conf_options = [
      "--enable-shared"
    ]

    # Setting up compilers
    self.CompilerSet(
      cflags='-fno-semantic-interposition',
      cxxflags='-fno-semantic-interposition')
      
  end

  def do_install

    dl = Download.new(@source_url, @src_dir)
    src_tarball_path = dl.GetPath

    fp = FNParser.new(@source_url)
    src_tarball_fname, src_tarball_bname = fp.name
    major, minor, patch = fp.version

    # puts src_tarball_fname, src_tarball_bname, major, minor, patch
    src_extract_folder = File.join(File.realpath(@build_dir), src_tarball_bname)
    src_build_folder = File.join(File.realpath(@build_dir), src_tarball_bname+'-build')
    @src_build_dir = src_build_folder

    if Dir.exists?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
    else
      puts "Extracting"
      self.Run( "tar xf "+File.realpath(File.join(@src_dir, src_tarball_fname))+" -C "+@build_dir )
    end

    if Dir.exists?(src_build_folder)
      puts "Build folder found!! Removing it for 'pure' experience!!"
      self.Run( "rm -rfv "+src_build_folder )
    else
      puts "Ok, let's make a build folder"
    end
    self.Run( "mkdir -p "+src_build_folder )

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
      "cd", src_build_folder, "&&",
      src_extract_folder+"/configure",
      opts.join(" "), "&&",
      "nice make -j", @Processors.to_s, "&&",
      inst_cmd
    ]

    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( env: @env, cmd: cmds.join(" ") )

    inst_module_cmds = [
      mod_sudo,
      File.join(@prefix,"bin/gem"),
      "install",
      @ruby_gems.join(" ")
    ]

    puts "Installing additional gems..."
    self.RunInstall( env: @env, cmd: inst_module_cmds.join(" ") )

    self.WriteInfo(
      build_system='make', 
      pkg_type='tar.gz', 
      destdir_inst_cmd="make DESTDIR=#{@stage_dir_pkg} install")
  end

end # class InstRuby
