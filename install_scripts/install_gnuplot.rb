#!/usr/bin/env ruby

$qt5_bin_path = File.join(ENV["HOME"], '.Qt/5.15.2/gcc_64/bin')

# this will handle Gnuplot

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

class InstGnuplot < InstallStuff

  def initialize(args)

    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]

    # Setting up compilers
    self.CompilerSet

    # build options
    @conf_options = []
    # Checking up qt5
    @conf_options += ["--with-qt=no"]
    qmake_cmd = self.qt5_qmake($qt5_bin_path)
    if qmake_cmd
      @conf_options -= ["--with-qt=no"]
      @conf_options += ["--with-qt=qt5"]
      # puts "qmake found (#{qmake_cmd}), enabling qt-terminal!!"
    end
    @conf_options += [
      "--with-readline=builtin",
      "--with-x",
      "--with-gd=#{@prefix}/lib",
      "--enable-backwards-compatibility",
    ]

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

    if Dir.exists?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
    else
      puts "Extracting"
      self.Run( "tar xf "+File.realpath(File.join(@src_dir, src_tarball_fname))+" -C "+@build_dir )
    end

    if Dir.exists?(src_build_folder)
      puts "Build folder found!! Removing it for 'pure' experience!!"
      self.Run( "rm -rf "+src_build_folder )
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
    self.WriteInfo
  end

end # class InstGnuplot
