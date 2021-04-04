#!/usr/bin/env ruby

# Installation script template class

require 'find'
require 'etc'
require 'open3'
require 'json'
require 'fileutils'
require 'tty-spinner'

require_relative '../utils/utils.rb'

class InstallStuff < RunConsole

  @souce_url = 'https://some_site.net.org/some_url-0.0.0'

  # Init stuff
  def initialize(pkgname, prefix, work_dirs=[], ver_check=true, verbose_mode=false)

    @pkgname=pkgname
    @prefix=File.realpath(prefix)

    @build_dir, @src_dir, @pkginfo_dir, @stage_dir = work_dirs

    @pkginfo_file = File.join(@pkginfo_dir, "#{@pkgname}.info" )
    @check_ver = ver_check
    @verbose = verbose_mode
    @Installed_files = []
    super(
      verbose: @verbose, 
      logf_dir: @pkginfo_dir, 
      logf_name: "#{@pkgname}.log")
    @run_install = true

    # Setting up processors
    @Processors = Etc.nprocessors

    @Version = SRC_VER[@pkgname].join('.')
    @conf_options = []
    @cmake_comp_settings = []
    @comp_settings = ''
    @env = {}

    @stage_dir_name = "#{@pkgname}-#{@Version}"

  end # initialize

  # Actually does install.
  def install
    self.ShowTitle
    self.SetURL
    if @run_install
      self.do_install
    end
  end

  # Get remote source URLs and version info. from it.
  def SetURL
    @source_url = SRC_URL[@pkgname]
    @ver_source = @Version
    # Version Checking
    if File.file?(@pkginfo_file) and self.VerCheck()
      @run_install = false
    else
      self.ShowInstallInfo
    end
  end

  # Shows package's name we are working on.
  def ShowTitle
    puts ""
    puts "Working on #{@pkgname} (#{@Version})!!"
    puts ""
  end

  # Snows summary of install command and environment variables.
  def ShowInstallInfo
    env_txt = ''
    if @env == nil
      return 0
    end
    @env.each do |k, flag|
      env_txt += "#{k}: #{flag}\n"
    end
    
    info_txt = %Q{
>> Installation Destination:
#{@prefix}

>> Config options
--prefix=#{@prefix}
#{@conf_options.join("\n")}

>> Compiler options (env)
#{env_txt}

    }
    puts info_txt
    sleep(2.5)
  end

  # Checking versin between installed ones and current url.
  # TODO Consider deleting it. 
  def VerCheck
    # Checking if newer version has rolled out
    if @check_ver
      # Do the version checking
      @ver_source = SRC_VER[@pkgname]
      if File.file?(@pkginfo_file)
        data_hash = JSON.parse(File.read(@pkginfo_file))
        @ver_current = Version.new(data_hash['Version'].join('.'))
        if (@ver_current >= @ver_source)
          puts "===================================================="
          puts "It seems Current version of #{@pkgname} is not so behind!"
          puts "Current #{@pkgname}: "+@ver_current.to_s
          puts "Source database #{@pkgname}: "+@ver_source.to_s
          puts "Consider updating the urls.json or keep it this way!"
          puts "===================================================="
          puts ""
          return true
        else
          puts "===================================================="
          puts "It seems current urls.json has newer version!!"
          puts "Current #{@pkgname}: "+@ver_current.to_s
          puts "Source database #{@pkgname}: "+@ver_source.to_s
          puts "Working on the newer version of #{@pkgname}!!"
          puts "===================================================="
          puts ""
          return false
        end
      else
        puts "===================================================="
        puts "No previous installation info. found for #{@pkgname}"
        puts "Working on the stuff anyway!"
        puts "===================================================="
        puts ""
        return false
      end
    end # if @check_ver

    return false
  end # VerCheck

  # Invoke it only if you have a valid prefix
  def CompilerSet(cflags='', cxxflags='', clang_mode=false)
    if !File.directory? @prefix
      puts "Cannot set a correct compiler with give path!"
      puts "Given path: #{@prefix}"
      puts "Reverting to default search path... /usr/bin"
      compiler_path = '/usr/bin'
    else
      compiler_path = File.join(@prefix, 'bin')
    end
    gc = GetCompiler.new(
      cc_path: compiler_path, cxx_path: compiler_path,
      cflags: cflags, cxxflags: cxxflags, 
      clang: false, suffix: nil, env_path: @prefix,
      verbose: false)
    @cmake_comp_settings += gc.get_cmake_settings
    @comp_settings += gc.get_env_str
    @env = @env.merge(gc.get_env_settings) {|key, oldval, newval| oldval+oldval}
  end

  # Qt5 existence check. (more likely qmake executable.)
  def qt5_qmake(qt5_path='')
    puts "Checking if the system has usable Qt5 ... "
    qmake_cmd = nil
    qmake_cmd_candidates = ['qmake', 'qmake5', 'qmake-qt5', 'qt5-qmake']
    # Search for package manager installed one. (System)
    qmake_cmd_candidates.each do |qm_cmd|
      qmake_cmd = UTILS.which(qm_cmd)
      if qmake_cmd
        puts "System qmake found!!: #{qmake_cmd}"
        return qmake_cmd
        break
      end
    end
    # If not found... try the default search path... for some people who 
    # actually installs Qt themselves.
    qmake_cmd = File.join(qt5_path, 'qmake')
    self.patch_qt5_pkgconfig(qt5_path)
    if File.exists? qmake_cmd
      @env["LDFLAGS"] += " -Wl,-rpath=#{qt5_path}/../lib"
      @env["PKG_CONFIG_PATH"] = "#{qt5_path}/../lib/pkgconfig:#{@env["PKG_CONFIG_PATH"]}"
      @env["PATH"] = "#{qt5_path}:#{ENV["PATH"]}"
      puts "Custom qmake found in ... #{qmake_cmd}"
      return qmake_cmd
    end
    
    puts "Looks like we don't have qmake in this system!"
    return nil
  end

  # Web installed Qt5 has weird pkgconfig lines... We fix them.
  def patch_qt5_pkgconfig(qt5_bin_path)
    qt5_pkgconfig_path = File.join(qt5_bin_path, '../lib/pkgconfig')
    pkgconfig_files = Dir["#{qt5_pkgconfig_path}/*.pc"]
    pkgconfig_files.each do |pkf|
      pc_txt = File.read(pkf)
      replaced_txt = pc_txt.gsub(/\/home\/qt\/work\/install/, qt5_bin_path)
      File.open(pkf, 'w') {|file| file.puts replaced_txt}
    end
  end

  # Collects the list of files installed
  def RunInstall(env: {}, cmd: '')
    if cmd.empty?
      return 0
    end
    self.Run( env, "#{cmd}" )
  end

  # Let's make a package of compiled file!
  # The code has been written for gnumake and ninja or possibly meson.
  # --> Make sure to impelement override for some packages..
  def MakePackage(build_system='make', pkg_type='tar.gz')
    cmd = [
      "cd #{@build_dir}",
      "DESTDIR=#{@stage_dir_name} #{build_system} install"
    ]
    self.Run(cmd.join(' && '))

    require 'pathname'
    @Installed_files = []
    Dir[@stage_dir_name] each do |file|
      abs_path = Pathname.new(File.realpath(file))
      proj_root = File.join(File.realpath(@stage_dir_name))
      @Installed_files << abs_path.relative_path_from(proj_root)
    end

    puts "Making package file for #{@pkgname} ... at #{@stage_dir_name}"
    
    make_tarball_cmd = ["cd #{@build_dir}"]
    tar_opt = {
      'tar.gz' => 'z',
      'tar.bz2' => 'j',
      'tar.xz' => 'J'
    }
    case pkg_type
    when 'tar.gz'
      make_tarball_cmd << "tar c#{pkg_type}f #{@stage_dir_name}.#{pkg_type} #{@stage_dir_name}"
    when 'tar.bz2'
      make_tarball_cmd << "tar c#{pkg_type}f #{@stage_dir_name}.#{pkg_type} #{@stage_dir_name}"
    when 'tar.xz'
      make_tarball_cmd << "tar c#{pkg_type}f #{@stage_dir_name}.#{pkg_type} #{@stage_dir_name}"
    end
    self.Run(make_tarball_cmd.join(' && '))

    # Finishing up...
    FileUtils.rm_rf(File.realpath(@stage_dir_name))

  end

  # Uninstallation!
  def uninstall
    puts "Uninstalling #{@pkgname} ... "
    spinner = TTY::Spinner("[Uninstalling] ... :spinner", format: :bouncing_ball)
    spinner.auto_rotate
    @Installed_files.each do |file|
      FileUtils.rm_rf(file)
    end
    FileUtils.rm_rf(@pkginfo_file)
    spinner.stop
    puts "#{@pkgname} uninstalled successfully!"
  end

  # Write package information.
  def WriteInfo
    puts "Writing package info for #{@pkgname}..."
    fp = File.open(@pkginfo_file, 'w')
    env_str = @env.map{|k,v| "{k}={v}".gsub('{k}', k).gsub('{v}', v)}.join("\n")

    unless @conf_options == []
      if @conf_options.join(' ').include?('-DCMAKE_INSTALL_PREFIX')
        conf_options_str = @conf_options.join(' ')
      else
        conf_options_str = "--prefix=#{@prefix} "+@conf_options.join(' ')
      end
    else
      conf_options_str = "N/A --> Probably the package was not based on automake or cmake."
    end

    compile_info_json = {
      "Package Name" => @pkgname,
      "Source file URL" => @source_url,
      "Version" => SRC_VER[@pkgname].to_sA,
      "Config options" => conf_options_str,
      "Env Variables" => env_str,
      "Installed Files" => @Installed_files,
    }
    fp.write(compile_info_json.to_json)

    fp.close
  end
end # class InstallStuff
