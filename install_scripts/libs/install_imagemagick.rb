#!/usr/bin/env ruby

# Install Imagemagick

require_relative '../../utils/utils.rb'
require_relative '../install_stuff.rb'

class InstImagemagick < InstallStuff

  def initialize(args)

    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]

    # mpich build options
    @conf_options = [
      "--sysconfdir=#{@prefix}/etc",
      "--with-modules",
      "--enable-hdri",
      "--with-modules",
      # "--with-perl",
      "--disable-static"
    ]

    # Setting up compilers
    self.CompilerSet

  end

  def do_install

    dl = Download.new(@source_url, @src_dir)
    src_tarball_path = dl.GetPath
    
    # Parsing name and version
    @src_tarball_fname = @source_url.split('/')[-1]
    @Version = @src_tarball_fname.split('-')[-2].split('.')

    # puts src_tarball_fname, src_tarball_bname, major, minor, patch
    src_extract_folder = File.join(File.realpath(@build_dir), "ImageMagick-#{@Version.join('.')}-0")
    src_build_folder = File.join(File.realpath(@build_dir), "ImageMagick-#{@Version.join('.')}-0"+'-build')
    @src_build_dir = src_build_folder

    if Dir.exists?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
    else
      puts "Extracting"
      self.Run( "tar xf "+File.realpath(File.join(@src_dir, @src_tarball_fname))+" -C "+@build_dir )
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
      inst_cmd = "sudo make install"
      mod_sudo = "sudo -H"
    else
      inst_cmd = "make install"
      mod_sudo = ""
    end

    # Ok let's roll!!
    cmds = [
      "cd", src_build_folder, "&&",
      File.join(src_extract_folder, "configure"),
      opts.join(" "), "&&",
      "make -j", @Processors.to_s, "&&",
      inst_cmd
    ]

    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( env: @env, cmd: cmds.join(" ") )
    self.WriteInfo
  end

end # class InstImagemagick
