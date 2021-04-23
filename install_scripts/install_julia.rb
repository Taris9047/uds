#!/usr/bin/env ruby

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

require 'open3'
require 'fileutils'

$julia_version = ["1", "6", "0"]


class InstJulia < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    @ver_check = false
    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)
    @source_url = SRC_URL[@pkgname]
    @source_dir = File.join(@src_dir, 'julia-src')
    @src_build_dir = File.join(@build_dir, 'julia-build')
    @target_dir = File.join(@prefix, '.opt', 'julia')
    @Version = $julia_version.join('.')

  end

  def do_install

    puts "Unfortunately, building julia isn't so stable!"
    puts "If it fails, it fails! ... especially on virtual machines."
    puts ""

    puts "Installing Julia"

    if File.directory?(@source_dir)
      puts "Julia src directory found! Deleting it!"
      FileUtils.rm_rf("#{@source_dir}")
    end
    self.Run( "cd #{@src_dir} && git clone #{@source_url} #{@source_dir}" )
    inst_cmd = [
      "cd #{@source_dir}",
      "git checkout v#{@Version}",
      "touch Make.user",
      "echo \"prefix=#{@target_dir}\" >./Make.user",
      "make install"
    ]
    self.RunInstall( env:@env, cmd: inst_cmd.join(' && ') )
    self.WriteInfo

  end

  def WriteInfo
    puts "Writing package info for #{@pkgname}..."
    fp = File.open(@pkginfo_file, 'w')
    compile_info_json = {
      "Package Name" => @pkgname,
      "Version" => @Version,
      "Installed Files" => @Installed_files+[File.join(julia_bin, 'julia')]
    }
    fp.write(compile_info_json.to_json)
    fp.close
  end

end # class InstJulia
