#!/usr/bin/env ruby

# Some distro needs newer cmake to do stuff.

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

$least_cmake_ver = ['3', '13', '4']

class InstCmake < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]

    # cmake build options
    @conf_options = ["--parallel=#{@Processors.to_s}", "--no-qt-gui"]

    # Checking up qt5
    qmake_cmd = self.qt5_qmake()
    if qmake_cmd
      @conf_options -= ["--no-qt-gui"]
      @conf_options += ["--qt-qmake=#{qmake_cmd}"]
      puts "qmake found (#{qmake_cmd}), enabling cmake-gui!!"
    end
    # Setting up compilers
    self.CompilerSet

  end

  def do_install

    o, e, s = Open3.capture3('echo $(cmake --version)')
    unless o.empty?
      preinstalled_cmake_ver = Version.new(o.split(' ')[2])
      least_cmake_ver = Version.new($least_cmake_ver.join('.'))
      if least_cmake_ver <= preinstalled_cmake_ver
        puts "It seems preinstalled cmake is version (#{preinstalled_cmake_ver.to_s})"
        puts "No need to install cmake on this system!"
        self.WriteInfo
        return 0
      end
    end

    puts ""
    puts "Working on #{@pkgname} (#{@ver_source.to_s})!!"
    puts ""

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
      self.Run( "rm -rfv "+src_build_folder )
    else
      puts "Ok, let's make a build folder"
    end
    self.Run( "mkdir -p "+src_build_folder )

    opts = ["--prefix=#{@prefix}"]+@conf_options

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

end # class InstCmake
