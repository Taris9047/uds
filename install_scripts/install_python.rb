#!/usr/bin/env ruby

# this will handle both Python 2 and 3

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

require 'fileutils'

$py2_modules = [
  'numpy', 'scipy', 'matplotlib', 
  'pycparser', 'sympy', 'nose'
]
$py2_conf_options = [
  "--enable-shared",
  "--enable-ipv6",
  "--enable-unicode=ucs4",
  "--with-threads",
  "--with-valgrind",
]

$py3_modules = [
  "autopep8", "xlrd", "xlsxwriter", "sphinx",
  "pylint", "pyparsing", "pyopengl",
  "numpy", "scipy", "matplotlib", "pandas", "nose",
  "sympy", "pyinstaller", "jupyter", "bpytop",
  "mercurial", "nose", "virtualenv"
]
$py3_conf_options = [
  "--enable-shared",
  "--enable-ipv6",
  "--enable-unicode=ucs4",
  "--with-threads",
  "--with-valgrind",
  "--with-ensurepip=yes",
  "--with-system-ffi",
  "--with-system-expat",
  "--enable-optimizations",
]


class InstPython2 < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]
    @get_pip_url = SRC_URL['get_pip']

    # Python2 modules to install
    @py2_modules = $py2_modules

    # Python2 build options
    @conf_options = $py2_conf_options+["--libdir=#{@prefix}/lib"]

    # Setting up compilers
    self.CompilerSet(
      cflags='-fno-semantic-interposition', cxxflags='-fno-semantic-interposition')

  end

  def do_install
    deprecation_txt = %Q{#{@pkgname} (#{@Version.to_s}) is completely deprecated as of now.
We still have this package since some old-school programs might still need them.
But installing it may cause some instability in the toolchain unless you know
what you are doing!!

** Press Ctrl+C to cancel the installation or just wait to continue the installation. **}
    puts deprecation_txt
    sleep(7)

    Download.new(@source_url, @src_dir)

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

    # Ok let's roll!!
    if @need_sudo
      inst_cmd = "sudo make install"
      pip_inst_sudo = "sudo -H"
    else
      inst_cmd = "make install"
      pip_inst_sudo = ""
    end

    # Rolling!
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    cmds = [
      "cd", src_build_folder, "&&",
      File.join(src_extract_folder,"configure"),
      opts.join(" "), "&&",
      "nice make -j", @Processors.to_s, "&&",
      inst_cmd
    ]
    self.RunInstall( env: @env, cmd: cmds.join(" ") )

    # It seems get-pip.py doesn't support python2 anymore
    puts "Running python2 -mensurepip"
    puts "Installing modules for #{@pkgname}"
    inst_pip_cmds = [
      pip_inst_sudo,
      File.join(@prefix, "bin/python"+major.to_s+"."+minor.to_s),
      "-mensurepip"
    ]
    # Changed to system instead of self.Run due to deprecation error message.
    system( inst_pip_cmds.join(" ") )
    pip_post_install_cmd = []
    if File.exists?(File.join(@prefix,"bin/pip"))
      pip_post_install_cmd = [
        pip_inst_sudo,
        'mv -fv',
        File.join(@prefix,"bin/pip"),
        File.join(@prefix,"bin/pip"+major.to_s)
      ]
    end
    system( pip_post_install_cmd.join(" ") )

    inst_module_cmds = [
      pip_inst_sudo,
      File.join(@prefix,"bin/pip"+major.to_s),
      "install -U",
      @py2_modules.join(" "),
      "&&",
      "rm -rf #{@prefix}/bin/isympy"
    ]
    self.RunInstall( cmd: inst_module_cmds.join(" ") )
    self.WriteInfo

  end
end # class InstPython2


class InstPython3 < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]
    @get_pip_url = SRC_URL['get_pip']

    # Python3 modules to install
    @py3_modules = $py3_modules

    # Python2 build options
    @conf_options = $py3_conf_options+["--libdir=#{@prefix}/lib"]

    # Setting up compilers
    self.CompilerSet(
      cflags='-fno-semantic-interposition', cxxflags='-fno-semantic-interposition')

  end

  def do_install

    Download.new(@source_url, @src_dir)

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
      inst_cmd = "sudo -H make install"
      pip_inst_sudo = "sudo -H"
    else
      inst_cmd = "make install"
      pip_inst_sudo = ""
    end

    # Ok let's roll!!
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    cmds = [
      "cd", src_build_folder, "&&",
      File.join(src_extract_folder,"configure"),
      opts.join(" "), "&&",
      "nice make -j", @Processors.to_s, "&&",
      inst_cmd
    ]
    self.RunInstall( env: @env, cmd: cmds.join(" ") )

    if File.exists?(File.join(@src_dir, 'get-pip.py'))
      puts "Found get-pip.py"
    else
      Download.new(@get_pip_url, @src_dir)
    end

    puts "Installing modules for #{@pkgname}"
    inst_pip_cmds = [
      pip_inst_sudo,
      File.join(@prefix, "bin/python"+major.to_s+"."+minor.to_s),
      File.realpath(File.join(@src_dir, 'get-pip.py')),
      "&&",
      pip_inst_sudo,
      "mv -fv",
      File.join(@prefix,"bin/pip"),
      File.join(@prefix,"bin/pip"+major.to_s)
    ]
    self.RunInstall( cmd: inst_pip_cmds.join(" ") )

    inst_module_cmds = [
      pip_inst_sudo,
      File.join(@prefix,"bin/pip"+major.to_s),
      "install -U",
      @py3_modules.join(" ")
    ]
    self.RunInstall( env: @env, cmd: inst_module_cmds.join(" ") )
    self.WriteInfo

  end
end # class InstPython3
