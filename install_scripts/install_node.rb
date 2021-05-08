#!/usr/bin/env ruby

# this will handle Node.js with NPM

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

$conf_options = [
  "--shared-zlib"
]

$npm_global_pkgs = [
  "npm@latest",
  "yarn",
  "hjson",
  "pkg",
  "n"
]

class InstNode < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]
    @bin_url = DB_PKG[@pkgname]["bin_url"]

    # Let's save some time!
    @bin_install = true

    # Setting up compilers
    self.CompilerSet
    @conf_options = $conf_options

  end

  def do_install
    if @bin_install
      self.do_bin_install
    else
      self.do_src_install
    end
  end # do_install

  # Let's not waste time on compiling a huge package on a crappy machine.
  def do_bin_install

    puts "Downloading binary packages from ... #{@bin_url}"
    @bin_fname = @bin_url.split('/')[-1]
    @bin_fname_base = @bin_fname.split('.')[0..-3].join('.')

    Download.new(@bin_url, @src_dir, source_ctl='', mode='wget', 
    source_ctl_opts='')

    ver = @bin_fname_base.split('-')[1].delete('v')
    @Version = ver.split('.')

    puts "Extracting the binary package ..."
    self.Run("tar xvf #{File.join(@src_dir, @bin_fname)} -C #{@build_dir}/")

    puts "Installing to #{@prefix} directory!"
    if @need_sudo
      sudo_cmd = 'sudo -H'
    else
      sudo_cmd = ''
    end
    cmd = [
      sudo_cmd,
      'cp -vfr',
      "#{File.join(@build_dir, @bin_fname_base)}/bin",
      "#{@prefix}/", "&&",
      sudo_cmd,
      'cp -vfr',
      "#{File.join(@build_dir, @bin_fname_base)}/include",
      "#{@prefix}/", "&&",
      sudo_cmd,
      'cp -vfr',
      "#{File.join(@build_dir, @bin_fname_base)}/lib",
      "#{@prefix}/", "&&",
      sudo_cmd,
      'cp -vfr',
      "#{File.join(@build_dir, @bin_fname_base)}/share",
      "#{@prefix}/",
    ]

    self.RunInstall( cmd: cmd.join(' ') )

    self.WriteInfo(build_system='bin')

    puts "Let's install additional packages!"
    npm_cmd = File.join(@prefix,'bin/npm')
    self.RunInstall( cmd: "#{npm_cmd} install -g #{$npm_global_pkgs.join(' ')}" )

  end # do_bin_install

  # The old-school way. Compile everything!!
  def do_src_install

    puts "Downloading source from ... "+@source_url
    Download.new(@source_url, @src_dir)
    fp = FNParser.new(@source_url)
    src_tarball_fname, src_tarball_bname = fp.name
    # major, minor, patch = fp.version

    src_extract_folder = File.join(@build_dir, src_tarball_bname)
    @src_build_dir = src_extract_folder

    if Dir.exists?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
      puts "Deleting it"
      self.Run( ['rm -rf', src_extract_folder].join(' ') )
    end
    puts "Extracting..."
    self.Run( "tar xf "+File.realpath(File.join(@src_dir, src_tarball_fname))+" -C "+@build_dir )

    opts = ["--prefix="+@prefix]+@conf_options

    if @need_sudo
      inst_cmd = "sudo make install"
    else
      inst_cmd = "make install"
    end

    @env['CC'] = 'gcc'
    @env['CXX'] = 'g++'

    # Ok let's rock!
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    cmds = [
      "cd", src_extract_folder, "&&",
      File.join(src_extract_folder,"configure"),
      opts.join(" "), "&&",
      "nice make -j", @Processors.to_s, "&&",
      inst_cmd
    ]
    self.RunInstall( env: @env, cmd: cmds.join(" ") )

    self.WriteInfo

    puts "Let's install additional packages!"
    npm_cmd = File.join(@prefix,'bin/npm')
    self.RunInstall( cmd: "#{npm_cmd} install -g #{$npm_global_pkgs.join(' ')}" )

  end # do_src_install

end # class InstNode



# Class InstNodeLTS
class InstNodeLTS < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]
    @bin_url = DB_PKG[@pkgname]["bin_url"]

    # Let's save some time!
    @bin_install = true

    # Setting up compilers
    self.CompilerSet
    @conf_options = $conf_options

  end

  def do_install
    if @bin_install
      self.do_bin_install
    else
      self.do_src_install
    end
  end # do_install

  def do_bin_install

    puts "Downloading binary packages from ... #{@bin_url}"
    @bin_fname = @bin_url.split('/')[-1]
    @bin_fname_base = @bin_fname.split('.')[0..-3].join('.')

    dl = Download.new(@bin_url, @src_dir, source_ctl='', mode='wget', 
    source_ctl_opts='')

    ver = @bin_fname_base.split('-')[1].delete('v')
    @Version = ver.split('.')

    puts "Extracting the binary package ..."
    self.Run("tar xvf #{File.join(@src_dir, @bin_fname)} -C #{@build_dir}/")

    puts "Installing to #{@prefix} directory!"
    if @need_sudo
      sudo_cmd = 'sudo -H'
    else
      sudo_cmd = ''
    end
    cmd = [
      sudo_cmd,
      'cp -vfr',
      "#{File.join(@build_dir, @bin_fname_base)}/bin",
      "#{@prefix}/", "&&",
      sudo_cmd,
      'cp -vfr',
      "#{File.join(@build_dir, @bin_fname_base)}/include",
      "#{@prefix}/", "&&",
      sudo_cmd,
      'cp -vfr',
      "#{File.join(@build_dir, @bin_fname_base)}/lib",
      "#{@prefix}/", "&&",
      sudo_cmd,
      'cp -vfr',
      "#{File.join(@build_dir, @bin_fname_base)}/share",
      "#{@prefix}/",
    ]

    self.RunInstall( cmd: cmd.join(' ') )

    self.WriteInfo(build_system='bin')

    puts "Let's install additional packages!"
    npm_cmd = File.join(@prefix,'bin/npm')
    self.RunInstall( cmd: "#{npm_cmd} install -g #{$npm_global_pkgs.join(' ')}" )

  end # do_bin_install

  def do_src_install

    puts "Downloading source from ... "+@source_url
    dl = Download.new(@source_url, @src_dir)
    fp = FNParser.new(@source_url)
    src_tarball_fname, src_tarball_bname = fp.name
    major, minor, patch = fp.version

    src_extract_folder = File.join(@build_dir, src_tarball_bname)
    @src_build_dir = src_extract_folder

    if Dir.exists?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
      puts "Deleting it"
      self.Run( ['rm -rf', src_extract_folder].join(' ') )
    end
    puts "Extracting..."
    self.Run( "tar xf "+File.realpath(File.join(@src_dir, src_tarball_fname))+" -C "+@build_dir )

    opts = ["--prefix="+@prefix]+@conf_options

    if @need_sudo
      inst_cmd = "sudo make install"
    else
      inst_cmd = "make install"
    end

    @env['CC'] = 'gcc'
    @env['CXX'] = 'g++'

    # Ok let's rock!
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    cmds = [
      "cd", src_extract_folder, "&&",
      File.join(src_extract_folder,"configure"),
      opts.join(" "), "&&",
      "nice make -j", @Processors.to_s, "&&",
      inst_cmd
    ]
    self.RunInstall( env: @env, cmd: cmds.join(" ") )

    self.WriteInfo

    puts "Let's install additional packages!"
    npm_cmd = File.join(@prefix,'bin/npm')
    self.RunInstall( cmd: "#{npm_cmd} install -g #{$npm_global_pkgs.join(' ')}" )

  end # do_src_install
end # class InstNode
