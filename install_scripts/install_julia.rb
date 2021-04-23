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
    @target_dir = File.join(@prefix, '.opt')
    @Version = $julia_version.join('.')

  end

  def do_install

    puts "Unfortunately, building julia isn't so stable!"
    puts "If it fails, it fails! ... especially on virtual machines."
    puts ""

    puts "Installing Julia"
    if !File.directory?(@target_dir)
      if !need_sudo
        FileUtils.mkdir_p("#{@target_dir}", verbose: true)
      else
        self.Run( "sudo mkdir -pv #{@target_dir}" )
      end
    end
    @src_dir = File.join(@target_dir, 'julia-src')
    if File.directory?(@src_dir)
      puts "Julia src directory found! Deleting it!"
      FileUtils.rm_rf("#{@src_dir}")
    end
    self.Run( "cd #{@target_dir} && git clone #{@source_url} #{@src_dir}" )
    self.RunInstall( env:@env, cmd: "cd #{@src_dir} && git checkout v#{@Version} && make" )
    julia_bin = File.join(@src_dir, 'julia')

    puts "Compilation finished! Linking executable!"
    julia_bin = File.join(@prefix, 'bin')
    if !File.directory?(julia_bin)
      self.Run( "mkdir -pv #{julia_bin}" )
    end
    FileUtils.ln_s "#{julia_bin}", "#{File.join(julia_bin, 'julia')}", force:true, verbose:true

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
