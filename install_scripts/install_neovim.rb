#!/usr/bin/env ruby

require 'etc'
require 'open3'

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

class InstNeovim < InstallStuff

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

    if @need_sudo
      inst_cmd = "sudo make install"
    else
      inst_cmd = "make install"
    end

    # Setting up makefile arguments
    @conf_options = \
      [
        "CMAKE_BUILD_TYPE=Release",
        "CMAKE_EXTRA_FLAGS=\"-DCMAKE_INSTALL_PREFIX=#{@prefix}\""
      ]
    @makefile_options = @conf_options.join(' ')

    # Setting up install prefix and configuration options...
    compile_cmd = [
      "cd", @build_dir, "&&",
      "git checkout v0.9.5", "&&",
      "make distclean", "&&",
      "nice make #{@makefile_options}", "&&",
      inst_cmd
    ]

    # self.Run( cmd.join(" ") )

    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( cmd: compile_cmd.join(' ') )

    @conf_options = configure_opts+comp_settings

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

end # InstNeovim
