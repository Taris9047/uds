#!/usr/bin/env ruby

# TODO: pdflib has a bit of different file structure. -> Installation script needs to be totally re-written.

# Install libPDFLib

# Super simple bainary copying...

require_relative '../../utils/utils.rb'
require_relative '../install_stuff.rb'

require 'fileutils'

class InstPDFLib < InstallStuff

  def initialize(args)

    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, ver_check=false, @verbose_mode)

    @source_url = SRC_URL[@pkgname]

    @run_install = true
    if File.exist? (File.join(@prefix, 'lib/libpdf.a')) and File.exist? (File.join(@prefix, 'include/pdflib.h'))
      puts "Looks like pdflib has already been installed!!"
      @run_install = false
    end

  end

  def do_install

    if !@run_install
      exit(0)
    end

    dl = Download.new(@source_url, @src_dir, source_ctl='', mode='wget', source_ctl_opts='')
    src_tarball_path = dl.GetPath

    # This also has weird version naming...
    @src_tarball_fname = @source_url.split('/')[-1]
    @src_tarball_bname = @src_tarball_fname.split('.')[0..-3].join('.')

    # puts src_tarball_fname, src_tarball_bname, major, minor, patch
    src_extract_folder = File.join(File.realpath(@build_dir), @src_tarball_bname)
    src_build_folder = File.join(File.realpath(@build_dir), @src_tarball_bname+'-build')

    if Dir.exist?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
    else
      puts "Extracting"
      self.Run( "tar xf "+File.realpath(File.join(@src_dir, @src_tarball_fname))+" -C "+@build_dir )
    end

    if @need_sudo
      sudo_cmd = "sudo"
    else
      sudo_cmd = ''
    end

    # Ok let's roll!!
    cmds = []
    if !File.directory? (File.realpath(@prefix, 'include'))
      cmds.append("mkdir -pv #{@prefix}/include")
    end
    if !File.directory? (File.realpath(@prefix, 'lib'))
      cmds.append("mkdir -pv #{@prefix}/lib")
    end
    cmds = [
      "#{sudo_cmd} cp -vfr #{File.join(src_extract_folder,'/bind/c/include/pdflib.h')} #{File.join(@prefix, 'include/')}",
      "#{sudo_cmd} cp -vfr #{File.join(src_extract_folder,'/bind/c/lib/libpdf.a')} #{File.join(@prefix, 'lib/')}"
    ]

    puts "Installing binaries..."
    self.RunInstall( cmd: cmds.join(" && ") )
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

end # class InstPDFLib