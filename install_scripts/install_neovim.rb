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
    
    #
    # Vim's configure cannot be called from out of repository directory!!
    # So, we need to use repository directory as build dir.
    #
    @build_dir = @src_dir

    # if Dir.exists?(@build_dir) == false
    #   puts "Build dir missing.. making one.."
    # else
    #   puts "Build dir exists, cleaning up before work!!"
    #   self.Run( "rm -rf "+@build_dir )
    # end
    # self.Run( "mkdir -p "+@build_dir )

    if @need_sudo
      inst_cmd = "sudo make install DESTDIR=#{@prefix}"
    else
      inst_cmd = "make install DESTDIR=#{@prefix}"
    end

    # Setting up makefile arguments
    @conf_options = \
      [
        "CMAKE_BUILD_TYPE=Release",
      ]
    @makefile_options = @conf_options.join(' ')

    # Setting up install prefix and configuration options...
    compile_cmd = [
      "cd",
      @build_dir,
      "&&",
      "nice make #{@makefile_options}",
      "&&",
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
