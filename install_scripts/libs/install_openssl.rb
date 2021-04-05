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
      "--openssldir=#{@prefix}",
      "shared",
      "zlib"
    ]

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

    if Dir.exists?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
    else
      puts "Extracting"
      self.Run( "tar xf "+File.realpath(File.join(@src_dir, src_tarball_fname))+" -C "+@build_dir )
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
      src_extract_folder+"/config",
      opts.join(" "), "&&",
      "make -j", @Processors.to_s, "&&",
      inst_cmd
    ]

    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( env: @env, cmd: cmds.join(" ") )
    self.WriteInfo
  end

  # Overriden due to specific make script.
  def MakePackage(build_system='make', pkg_type='tar.gz')
    cmd = [
      "cd #{@src_build_dir}",
      "#{build_system} DESTDIR=#{@stage_dir_pkg} install"
    ]
    self.Run(cmd.join(' && '))

    require 'pathname'
    @Installed_files = []
    Dir[@stage_dir_pkg].each do |file|
      abs_path = Pathname.new(File.realpath(file))
      proj_root = File.join(File.realpath(@stage_dir_pkg))
      @Installed_files << abs_path.relative_path_from(proj_root)
    end

    puts "Making package file for #{@pkgname} ... at #{@stage_dir_pkg}"
    
    make_tarball_cmd = ["cd #{@stage_dir}"]
    tar_opt = {
      'tar.gz' => 'z',
      'tar.bz2' => 'j',
      'tar.xz' => 'J'
    }
    case pkg_type
    when 'tar.gz'
      make_tarball_cmd << "tar c#{tar_opt[pkg_type]}f #{@stage_dir_name}.#{pkg_type} #{@stage_dir_pkg}"
    when 'tar.bz2'
      make_tarball_cmd << "tar c#{tar_opt[pkg_type]}f #{@stage_dir_name}.#{pkg_type} #{@stage_dir_pkg}"
    when 'tar.xz'
      make_tarball_cmd << "tar c#{tar_opt[pkg_type]}f #{@stage_dir_name}.#{pkg_type} #{@stage_dir_pkg}"
    end
    self.Run(make_tarball_cmd.join(' && '))

    # Finishing up...
    FileUtils.rm_rf(File.realpath(@stage_dir_pkg))

  end


end # class InstLibOpenSSL