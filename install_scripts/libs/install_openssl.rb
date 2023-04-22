#!/usr/bin/env ruby

require_relative '../../utils/utils.rb'
require_relative '../install_stuff.rb'

class InstLibOpenSSL < InstallStuff

  def initialize(args)

    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]

    # build options
    @conf_options = [
      "--libdir=#{File.join(@prefix, 'lib')}",
      # "--openssldir=#{@prefix}",
      "shared",
      "zlib"
    ]

    # Setting up correct openssl dir
    if UTILS.which('/usr/bin/openssl')
      openssl_dir = `/usr/bin/openssl version -d`.split(' ')[-1].gsub("\"","")
    else
      openssl_dir = File.join(@prefix, 'ssl')
    end

    @conf_options += [ "--openssldir=#{openssl_dir}" ]

    # Setting up compilers
    self.CompilerSet

  end

  def do_install

    dl = Download.new(@source_url, @src_dir)
    src_tarball_path = dl.GetPath

    fp = FNParser.new(@source_url)
    src_tarball_fname, src_tarball_bname = fp.name
    major, minor, patch = fp.version

    # puts src_tarball_fname, src_tarball_bname, major, minor, patch
    src_extract_folder = File.join(File.realpath(@build_dir), src_tarball_bname)
    src_build_folder = File.join(File.realpath(@build_dir), src_tarball_bname+'-build')
    @src_build_dir = src_build_folder

    if Dir.exist?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
    else
      puts "Extracting"
      self.Run( "tar xf "+File.realpath(File.join(@src_dir, src_tarball_fname))+" -C "+@build_dir )
    end

    if Dir.exist?(src_build_folder)
      puts "Build folder found!! Removing it for 'pure' experience!!"
      self.Run( "rm -rfv "+src_build_folder )
    else
      puts "Ok, let's make a build folder"
    end
    self.Run( "mkdir -p "+src_build_folder )

    opts = ["--prefix="+@prefix]+@conf_options

    if @need_sudo
      inst_cmd = "sudo make install_sw"
      mod_sudo = "sudo -H"
    else
      inst_cmd = "make install_sw"
      mod_sudo = ""
    end

    # Ok let's roll!!
    cmds = [
      "cd", src_build_folder, "&&",
      src_extract_folder+"/config",
      opts.join(" "), "&&",
      "make -j", @Processors.to_s, "&&",
      inst_cmd
    ]

    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( env: @env, cmd: cmds.join(" ") )
    self.WriteInfo(
      build_system='make', 
      pkg_type='tar.gz', 
      destdir_inst_cmd="make DESTDIR=#{@stage_dir_pkg} install_sw")
  end

end # class InstLibOpenSSL