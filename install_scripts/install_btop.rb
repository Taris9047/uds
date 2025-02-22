#!/usr/bin/env ruby

# Handles BTOP installation

require 'etc'
require 'open3'

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

class InstBTOP < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    self.CompilerSet

  end

  def do_install

    dn = Download.new(@source_url, destination=@src_dir, source_ctl='git')
    @src_dir = dn.GetPath

    # Let's build!!
    @build_dir = @src_dir

    # BTOP Doesn't have conventional configure script. It's all makefile.
    #@make_opts = [
    #  "STATIC=false",
    #  "ADDFLAGS=\"-march=native -fomit-frame-pointer -pipe #{$ldflags_static}\"",
    #  "LD_LIBRARY_PATH=\"#{@prefix}:#{$sys_gcc_lib_dir}/lib64:/usr/lib:/usr/lib64:/lib:/lib64\""
    #]
    @make_opts = []

    if @need_sudo
      inst_cmd = "sudo make install PREFIX=#{@prefix}"
    else
      inst_cmd = "make install PREFIX=#{@prefix}"
    end

    compile_cmd = [
      "cd",
      @build_dir,
      "&&",
      "nice make #{@make_opts.join(' ')}",
      "&&",
      inst_cmd
    ]
    
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( cmd: compile_cmd.join(' ') )

    @conf_options = @make_opts

    self.WriteInfo

  end

  def WriteInfo
    puts "Writing package info for #{@pkgname}..."
    fp = File.open(@pkginfo_file, 'w')
    compile_info_json = {
      "Package Name" => @pkgname,
      "Version" => ['0','0','0'],
      "Installed Files" => @Installed_files
    }
    fp.write(compile_info_json.to_json)
    fp.close
  end

end # InstVim
