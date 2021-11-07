#!/usr/bin/env ruby

require 'fileutils'
require 'tty-spinner'
require_relative './utils/utils.rb'

# Note that installing old gcc (gcccuda) is disabled due to libc 2.26 issue.
# In fact, we need to apply patch to adopt old gcc source codes to
# follow up the newest changes in libc 2.26

# Version
$version = ['1', '0', '8']

# title
$title = "Unix Development Environment setup"

# default install script directory
$def_inst_script_dir = './install_scripts'

#
# The main stuff handler class!
#
class UnixDevSetup

  def initialize(op_mode_list = [])

    # Default parameters
    home_dir = ENV["HOME"]
    def_prefix = File.join(home_dir, "/.local")
    # def_prefix = File.join("/usr/local")
    @list_of_progs = SRC_LIST[]

    @not_so_stable_pkgs = ['pypy3', 'clang', 'ROOT', 'julia']
    @not_so_needed_pkgs = [
      'gccold', 'cudacc', 'node-lts', 'ruby3', 'libjpeg', 'emacs',
      'gcc-jit'
    ]
    @deprecated_pkgs = ['python2']
    @not_really_a_pkg = ['get_pip', 'golang-bootstrap']

    @list_of_all = \
      @list_of_progs \
      - @not_so_stable_pkgs \
      - @not_so_needed_pkgs \
      - @not_really_a_pkg \
      - @deprecated_pkgs

    @aliases = TABLES.ALIAS_TABLE
    @aliases['all'] = @list_of_all

    @permitted_list = @list_of_progs + @aliases.keys
    @opt_list = [
      '--use-clang', 'prereq', '-v', '--verbose',
      'purge', '--purge', 'clean', '--clean', '--version',
      '--use-system-gcc', '-sgcc',
      '--force', '-f', '-u', 'uninstall', 'remove',
      '-l', 'list',
    ]
    @permitted_list += @opt_list

    # Default system ==> usually it's linux
    # TODO: implement platform detection stuff here later.
    @def_system = 'x86_64-linux-gnu'

    # Getting CWD
    @current_dir = File.expand_path(File.dirname(__FILE__))
    
    # Verbose mode? Default: false
    @verbose = false

    # Show title
    self.main_title

    # Directories
    # @work_dir_root = File.join(@current_dir, 'workspace')
    @work_dir_root = File.join(def_prefix, 'UDS_Cellar')
    @work_dir_path = File.join(@work_dir_root, 'build')
    @source_dir_path = File.join(@work_dir_root, 'download')
    # @pkginfo_dir_path = File.join(@current_dir, 'pkginfo')
    # @pkginfo_dir_path = File.join(ENV["HOME"], '.uds_pkginfo')
    @pkginfo_dir_path = File.join(@work_dir_root, 'pkginfo')
    @work_dir_log = File.join(@work_dir_root, 'log')
    @stage_dir = File.join(@work_dir_root, 'BrewedPackages')

    @prefix_dir_path = def_prefix
    @inst_script_dir=$def_inst_script_dir

    # Setting up operatnion mode and package lists.
    @op_mode_list = op_mode_list
    @pkgs_to_install = []
    @flag_wrong_pkg_given = false
    @wrong_pkgs = []
    @parameters = []

    # Sort out input arguments
    @op_mode_list.each do |opm|
      if @list_of_progs.include?(opm)
        @pkgs_to_install.push(opm)
      elsif @aliases.keys.include?(opm)
        @pkgs_to_install.push(@aliases[opm])
      elsif @opt_list.include?(opm)
        @parameters.push(opm)
      elsif opm == 'all'
        @pkgs_to_install = @list_of_all
      else
        @wrong_pkgs.push(opm)
      end
    end

    # Clang mode for some packages.
    @clang_mode = false
    # use system gcc instead of gcc included here.
    @use_system_gcc = false
    # Force install mode (no dep check.)
    @force_install_mode = false
    # uninstall mode?
    @uninstall_mode = false
    # list mode
    @list_mode = false
    self.__parse_params__
    unless @wrong_pkgs.empty?
      puts "Some wrong packages given! Ignoring them!"
      puts "#{@wrong_pkgs.join(' ')}"
      @flag_wrong_pkg_given = true
    end
    if @pkgs_to_install.empty?
      puts "No packages selected!"
      puts ""
      self.show_help
      exit(1)
    end

    # Set up console
    require_relative './utils/run_console.rb'
    @Con = RunConsole.new(verbose: @verbose, logf_dir: @work_dir_log)
    # Resolve dependencies.
    require './utils/utils.rb'
    if @uninstall_mode
      # Let's not worry about any dependency as of now...
      #
      # @pkgs_to_install = dep_resolve.GetUninstList()
      puts "List of packages to uninstall..."
      puts ""
      puts @pkgs_to_install.join(' ')
      puts ""
    else
      puts "Checking dependency for #{@pkgs_to_install.join(" ")}"
      dep_resolve = DepResolve.new(
        @pkgs_to_install,
        @pkginfo_dir_path,
        @force_install_mode,
        @use_system_gcc,
        @uninstall_mode)
      @pkgs_to_install = dep_resolve.GetInstList()
      # List packages to install
      if !dep_resolve.GetDepList().empty?
        puts "Following packages are selected to satisfy dependency."
        puts ""
        puts dep_resolve.PrintDepList()
        puts ""
      end
      puts "List of packages to install..."
      puts ""
      puts dep_resolve.PrintInstList()
      puts ""  
    end
    # Make or update workspace directories
    self.__setup_work_dirs__

    if File.directory? @pkginfo_dir
      @Installed_pkg_list = \
        Dir.entries(@pkginfo_dir).select { |f| f.include?('.info') }.map { |item| item.gsub('.info', '') }
    else
      @Installed_pkg_list = []
    end

    if @list_mode
      @pkgs_to_install.each do |pkg|
        if !@Installed_pkg_list.include?(pkg)
          next
        end
        puts "*** #{pkg} -- Installed Files:"
        pkg_info = self.ReadPkgInfo(pkg)
        file_list = pkg_info["Installed Files"]
        file_list.each do |f|
          puts f
        end
        puts ""
        puts ""
      end
      exit(0)
    end

    # Checking if the destination directory is writable or not.
    @need_sudo = !File.writable?(@prefix_dir)

    # Check version
    @vercheck = !@force_install_mode

    # TODO: Change class init arguemnt to hash based one.
    @inst_args = {
      "pkgname" => '',
      "prefix" => @prefix_dir,
      "os_type" => @def_system,
      "def_system" => @def_system,
      "work_dirs" => @work_dirs,
      "need_sudo" => @need_sudo,
      "verbose_mode" => @verbose,
      "ver_check" => @vercheck,
      "clang_mode" => @clang_mode,
    }

    self.install_pkgs

  end # UnixDevSetup::initialize

  # Remove default python cmd
  def remove_def_python_cmd
    puts "Removing 'python' command to preserve system native python..."
    sudo_cmd = ''
    if !File.writable?(@prefix_dir)
      sudo_cmd = "sudo -H"
    end
    del_python_cmd = [
      File.join($prefix_dir, "bin/python"),
      File.join($prefix_dir, "bin/ipython")
    ]
    del_python_cmd.each do |c|
      FileUtils.rm_rf(c)
    end
  end

  # Main title banner
  def main_title
    mt = %{
******************************************

  #{$title}"
  Version (#{$version.join('.')})"

******************************************
    }
    puts mt
  end

  # Help message
  def show_help
    main_title
    hlp = %{
  Usage: ./unix_dev_setup.rb <params_or_installable_pkgs>

  <params> can be:
  #{@opt_list.join(', ')}
  --use-clang: Some packages can be built with clang.
  -v,--verbose: Make it loud!
  --version: displays version info.
  --purge: deletes everything before installing any package including pkginfo dir.
  --clean: deletes working dirs before installing any package
  -sgcc,--use-system-gcc: uses system gcc instead of state-of-art one.
  -f,--force: ignores dependency check and install packages.
  -l, list <package>: shows files that a given package installed on the system.
  -u, uninstall, remove <package>: performs uninstallation.
  clean: deletes working dirs
  purge: purges all the working dirs including pkginfo dir.

  <installable_pkgs> can be:
  #{(@permitted_list-@opt_list).join(', ')}

  --> Note that node-lts replaces node and vice versa.
  --> Default installation is node(latest version)

  Some packages are not very stable at the moment:
  #{@not_so_stable_pkgs.join(', ')}

  More packages are coming!! Stay tuned!!
    }
    puts hlp
    exit(0)
  end

  def ReadPkgInfo(pkg_name)
    if !@pkginfo_dir
      return {}
    end
    return JSON.parse(File.read(File.join(@pkginfo_dir, pkg_name+'.info')))
  end

  def __parse_params__
    # Parsing operation parameters.
    # Get version
    if @parameters.include?('--version')
      puts "(UDE set) #{$title} Ver. #{$version.join('.')}"
      exit(0)
    end

    # Show help message and quit.
    if @parameters.include?('--help')
      self.show_help
    end

    # Handling Verbose mode
    if @parameters.include?('-v') or @parameters.include?('--verbose')
      @verbose = true
      puts ""
      puts "*** Verbose ON! It will be pretty loud! ***"
      puts "* Note that some compilation jobs might hang up with Verbose ON. *"
      puts ""
    end

    # Use clang as compiler
    if @parameters.include?('--use-clang')
      puts "Clang mode turned on. Some packages will be compiled with system llvm-clang."
      @clang_mode = true
    end

    # Some edge cases... cleaning and installing prereq
    if @parameters.include?('purge')
      puts "Purging everything!!!"
      spinner = TTY::Spinner.new("[Purging] ... :spinner", format: :bouncing_ball)
      spinner.auto_spin
      FileUtils.rm_rf(@work_dir_root)
      FileUtils.rm_rf(@pkginfo_dir_path)
      prefix_kill_list = Dir.entries(@prefix_dir_path)
      prefix_kill_list -= [ ".", "..", "share" ]
      prefix_kill_list += [ ".opt" ]
      prefix_kill_list = prefix_kill_list.uniq
      prefix_kill_list.each do |k|
        FileUtils.rm_rf(File.join(@prefix_dir_path, k))
      end
      spinner.stop
      puts "Purged everything!! Now you are free of cruds."
      exit(0)
    end
    if @parameters.include?('--purge')
      spinner = TTY::Spinner.new("[Purging] .. :spinner", format: :bouncing_ball)
      puts "Performing purge install..."
      spinner.auto_spin
      FileUtils.rm_rf(@pkginfo_dir_path)
      FileUtils.rm_rf(@work_dir_root)
      spinner.stop
      puts "Deleted every build stuff!!"
    end

    if @parameters.include?('clean')
      puts "Cleaning up source files and build dirs..."
      spinner = TTY::Spinner.new("[Cleaning] ... :spinner", format: :bouncing_ball)
      spinner.auto_spin
      FileUtils.rm_rf(@work_dir_root)
      log_files = Dir[File.join(@pkginfo_dir_path, '*.log')]
      log_files.each do |log_f|
        FileUtils.rm_rf(log_f)
      end
      spinner.stop
      puts "Cleaned up source files to save space!!"
      exit(0)
    end
    if @parameters.include?('--clean')
      puts "Performing clean install..."
      puts "Cleaning up source files and build dirs..."
      spinner = TTY::Spinner.new("[Cleaning] ... :spinner", format: :bouncing_ball)
      spinner.auto_spin
      FileUtils.rm_rf(@work_dir_root)
      spinner.stop
      puts "Cleaned up source files to save space!!"
    end
    
    if @parameters.include?('--use-system-gcc') or @parameters.include?('-sgcc')
      puts "Using system gcc!! i.e. /usr/bin/gcc"
      @use_system_gcc = true
    end

    if @parameters.include?('--force') or @parameters.include?('-f')
      puts "Foce install mode!"
      @force_install_mode = true
    end

    if @parameters.include?('-u') or @parameters.include?('uninstall') or @parameters.include?('remove')
      puts "Uninstalling packages!!"
      @uninstall_mode = true
    end

    if @parameters.include?('-l') or @parameters.include?('list')
      puts "Reading pkg file list"
      @list_mode = true
    end

    if @parameters.include?('prereq')
      puts ""
      puts "========================================================="
      puts "| It's recommended to run prereq. installation script!  |"
      puts "|                                                       |"
      puts "| Prereq. installation script: install_prereq.sh        |"
      puts "========================================================="
      puts ""
      exit(0)
    end

  end # def __parse_params__

  def __setup_work_dirs__
    # Working directories
    unless File.directory?(@work_dir_path)
      puts @work_dir_path+" not found, making one..."
      FileUtils.mkdir_p(@work_dir_path)
    end
    @work_dir = File.realpath(@work_dir_path)
    puts "Working directory will be: #{@work_dir}"

    unless File.directory?(@source_dir_path)
      puts @source_dir_path+" not found, making one..."
      FileUtils.mkdir_p(@source_dir_path)
    end
    @source_dir = File.realpath(@source_dir_path)
    puts "Source directory will be: #{@source_dir}"

    unless File.directory?(@pkginfo_dir_path)
      puts @pkginfo_dir_path+" not found, making one..."
      FileUtils.mkdir_p(@pkginfo_dir_path)
    end
    @pkginfo_dir = File.realpath(@pkginfo_dir_path)
    puts "Package information directory will be: #{@pkginfo_dir}"

    unless File.directory?(@stage_dir)
      puts @stage_dir+" not found, making one..."
      FileUtils.mkdir_p(@stage_dir)
    end
    # @stage_dir = File.realpath(@stage_dir)
    puts "Package staging directory will be: #{@stage_dir}"

    @work_dirs = [@work_dir, @source_dir, @pkginfo_dir, @stage_dir]

    unless File.directory?(@prefix_dir_path)
      puts @prefix_dir_path+" not found, making one..."
      FileUtils.mkdir_p(@prefix_dir_path)
    end
    @prefix_dir = File.realpath(@prefix_dir_path)
    puts "Prefix confirmed! Everything will be installed at..."
    puts @prefix_dir
    puts ""
      
  end # def __setup_work_dirs__


  def install_pkgs
    # The main installation loop
    unless @uninstall_mode
      @pkgs_to_install.each do |pkg|
        require "#{@inst_script_dir}/#{SRC_SCRIPT[pkg]}"
        @inst_args["pkgname"] = pkg
        inst = Object.const_get(SRC_CLASS[pkg]).new( @inst_args )
        inst.install
      end # @pkgs_to_install.each do |pkg|
    
    # Uninstallation loop
    else
      spinner = TTY::Spinner.new("[Uninstalling] ... :spinner", format: :bouncing_ball)
      spinner.auto_spin
      @pkgs_to_install.each do |pkg|
        if @Installed_pkg_list.include?(pkg)
          pkg_info = self.ReadPkgInfo(pkg)
          files_to_delete = pkg_info["Installed Files"]
          dirs_to_delete = []
          files_to_delete.each do |f|
            # do not delete non-empty directory
            if File.directory?(f)
              next
            else
              FileUtils.rm_rf(f)
            end
            # delete empty directory once files are deleted
            if File.directory?(f) and !dirs_to_delete.include?(File.dirname(f))
              dirs_to_delete += [File.dirname(f)]
            end
          end
          dirs_to_delete.each do |d|
            if Dir.empty? (d)
              FileUtils.rmdir(d)
            end
          end
          FileUtils.rm_rf(File.join(File.realpath(@pkginfo_dir), pkg+'.info'))
          FileUtils.rm_rf(File.join(File.realpath(@pkginfo_dir), pkg+'.log'))
        end
      end # @pkgs_to_install.each do |pkg|
      spinner.stop
      puts "Uninstallation complete!"
    end

    if @flag_wrong_pkg_given
      puts ""
      puts "Looks like there were some pkgs weren't recognized!!"
      puts ""
      puts "Wrong pkgs:"
      puts @wrong_pkgs.join(" ")
      puts ""
      puts "Available modules are..."
      puts ""
      @list_of_progs.each do |pkg|
        puts pkg
      end
    end

  end



end # UnisDevSetup

dev = UnixDevSetup.new(ARGV)

puts ""
puts "Jobs finished!!"
puts ""
