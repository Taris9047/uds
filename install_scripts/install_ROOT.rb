#!/usr/bin/env ruby

# Installing ROOT

require 'etc'
require 'open3'

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

$root_version = ["6", "24", "00"]

class InstROOT < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)
    @def_system = @os_type

    # Setting up compilers
    self.CompilerSet

  end

  def do_install

    @root_prefix = File.join(@prefix, '/.opt/ROOT')
    if !File.directory? File.join(@prefix, '/.opt')
      self.Run('mkdir -pv '+File.join(@prefix, '/.opt'))
      self.Run('ln -sfv '+File.join(@prefix, '/.opt')+' '+File.join(@prefix, '/opt'))
    end
    @src_url = SRC_URL['ROOT']
    branch_opts = "-b v#{$root_version[0]}-#{$root_version[1]}-#{$root_version[2]}"
    dn = Download.new(
      @src_url, destination=@src_dir, source_ctl='git', mode='git', source_ctl_opts=branch_opts)
    @src_dir = dn.GetPath

    # Let's build!!
    @build_dir = File.join(@build_dir, "ROOT-build")
    @src_build_dir = @build_dir
    if Dir.exists?(@build_dir) == false
      puts "Build dir missing.. making one.."
    else
      puts "Build dir exists, cleaning up before work!!"
      self.Run( "rm -rf "+@build_dir )
    end
    self.Run( "mkdir -p "+@build_dir )

    if @need_sudo
      inst_cmd = "sudo make install"
    else
      inst_cmd = "make install"
    end

    # Setting up install prefix
    inst_prefix_opt = [ "-DCMAKE_INSTALL_PREFIX:PATH=#{@root_prefix}" ]

    py_src = SRC_URL['python3']
    fnp = FNParser.new(py_src)
    py_ver = fnp.version
    cmake_opts = [
      "-DCMAKE_BUILD_TYPE=Release",
      "-DLLVM_BUILD_TYPE=Release",
      "-DPYTHON_EXECUTABLE=#{@prefix}/bin/python#{py_ver[0]}",
	    "-Drpath=ON",
    ]

    config_cmd = [
      "cd",
      @build_dir,
      "&&",
      "cmake",
      @src_dir,
      inst_prefix_opt,
      cmake_opts.join(' '),
      @cmake_comp_settings.join(' '),
    ]

    compile_cmd = [
      "cd",
      @build_dir,
      "&&",
      "nice make -j #{@Processors}",
      "&&",
      inst_cmd
    ]

    puts "Configuring with cmake"
    self.Run( @env, config_cmd.join(' ') )

    @Version = $root_version
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( env: @env, cmd: compile_cmd.join(' ') )

    @conf_options = [inst_prefix_opt]+cmake_opts+@cmake_comp_settings
    self.WriteInfo

  end

  def WriteInfo
    puts "Writing package info for #{@pkgname}..."
    fp = File.open(@pkginfo_file, 'w')
    compile_info_json = {
      "Package Name" => @pkgname,
      "Version" => @Version,
      "Installed Files" => @Installed_files
    }
    fp.write(compile_info_json.to_json)
    fp.close
  end

end # InstClang
