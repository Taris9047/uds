#!/usr/bin/env ruby

# Installing DUF

require 'etc'
require 'open3'

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

class InstDUF < InstallStuff

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

    @src_url = SRC_URL['duf']
    dn = Download.new(
      @src_url, destination=@src_dir, source_ctl='git', mode='git')
    @src_dir = dn.GetPath

    # Let's build!!
    @build_dir = @src_dir

    inst_cmd = "cp -vf #{@build_dir}/duf #{@prefix}/bin/duf"
    if @need_sudo
      inst_cmd = [ "sudo", inst_cmd ].join(' ')
    end

    compile_cmd = [
      "cd",
      @build_dir,
      "&&",
      "go build",
      "&&",
      inst_cmd
    ]

    puts "Building with Go and Installing ..."
    self.RunInstall( env: @env, cmd: compile_cmd.join(' ') )
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

end # Instduf