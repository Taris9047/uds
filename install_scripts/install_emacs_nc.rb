#!/usr/bin/env ruby
# this will handle emacs with native-compiler

# Additional deps for Ubuntu 20.04
#
# libgccjit0 libgccjit10-dev texinfo
#
# Ubuntu 18.04 needs
#
# libgccjit0 libgccjit-7-devs

# Additional deps for Fedora
#
# libgccjit-devel texinfo
# 

$newest_gcc_ver = '10'

require 'fileutils'
require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

class InstEmacsNC < InstallStuff

  def initialize(args)

    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]

    # Setting up compilers
    self.CompilerSet

    # build options
    @conf_options = []
    # Checking up qt5
    @conf_options += [
      '--with-modules',
      '--with-xft',
      '--with-file-notification=inotify',
      '--with-x=yes',
      '--with-x-toolkit=gtk3',
      '--with-xwidgets',
      '--with-lcms2',
      '--with-giflib',
#      '--with-imagemagick',
      '--with-mailutils',
      '--with-pop',
      '--with-native-compilation',
    #  '--with-xwidgets'    # needs webkitgtk4-dev
    ]

    # TODO: Implement more elegant way to find out jit enabled gcc
    #
    self.detect_libgccjit
  
  end # initialize

  def detect_libgccjit
    gcc_jit_found = false
    libgccjit_found = false
    @gcc_prefix = @prefix
    if UTILS.which('gcc-jit')
      @env["CC"] = 'gcc-jit'
      gcc_jit_found = true
      libgccjit_found = true
    elsif UTILS.which("gcc-#{$newest_gcc_ver}")
      @env["CC"] = "gcc-#{$newest_gcc_ver}"
    else
      @env["CC"] = 'gcc'
    end
    if UTILS.which('g++-jit')
      @env["CXX"] = 'g++-jit'
      gcc_jit_found = true
      libgccjit_found = true
    elsif UTILS.which("gcc-#{$newest_gcc_ver}")
      @env["CXX"] = "gcc-#{$newest_gcc_ver}"
    else
      @env["CXX"] = 'g++'
    end

    # Detect whether current gcc has libgccjit capability.
    @gcc_prefix = File.realpath(File.join(File.dirname(UTILS.which(@env["CC"])), '..'))

    if gcc_jit_found
      @env["C_INCLUDE_PATH"] = "#{@gcc_prefix}/include:"+@env["C_INCLUDE_PATH"]
      @env["CPLUS_INCLUDE_PATH"] = "#{@gcc_prefix}/include:"+@env["CPLUS_INCLUDE_PATH"]
      @env["LDFLAGS"] = "-Wl,-rpath=#{@gcc_prefix}/lib -Wl,-rpath=#{@gcc_prefix}/lib64 "+@env["LDFLAGS"]
      return true
    else
      # Since we are working with system installed gcc, we can browse it even
      # further since they keep them in pretty peculiar places.
      search_result = `find #{@gcc_prefix} | grep libgccjit`
      if search_result.include? 'libgccjit'
        @env["LDFLAGS"] += " "+["-Wl,-rpath=#{@gcc_prefix}/lib/x86_64-linux-gnu"].join(' ')
        libgccjit_found = true
        return libgccjit_found
      end

      unless libgccjit_found
        puts "Oops, current compiler #{@env["CC"]} cannot support jit!!"
        puts "Exiting!!"
        exit 1
      end
    end

    return libgccjit_found
  end # detect_libgccjit

  def do_install
    warn_txt = %q{
*** Note ***
 Emacs native-compiler (GccEmacs) is an experiemental program.
 Many rolling distros provide this version with repl or copr.
 So, it's better to use them instead of this head-bonking source compile.
*** **** ***
}      
    puts warn_txt
    sleep (2)

    dl = Download.new(@source_url, @src_dir,
        source_ctl='git', mode='wget',
        source_ctl_opts="#{@pkgname} -b feature/native-comp")
    src_clone_path = dl.GetPath

    # puts src_tarball_fname, src_tarball_bname, major, minor, patch
    src_clone_folder = File.join(File.realpath(@src_dir), "#{@pkgname}")
    src_build_folder = File.join(File.realpath(@build_dir), "#{@pkgname}-build")

    if Dir.exists?(src_build_folder)
      puts "Build folder found!! Removing it for 'pure' experience!!"
      self.Run( "rm -rf "+src_build_folder )
    else
      puts "Ok, let's make a build folder"
    end
    self.Run( "mkdir -p "+src_build_folder )

    opts = ["--prefix=#{@prefix}"]+@conf_options

    if @need_sudo
      inst_cmd = "sudo -H make install"
    else
      inst_cmd = "make install"
    end

    # Ok let's roll!!
    cmds = [
      "cd #{src_clone_folder}", "&&",
      "./autogen.sh", "&&",
      "cd #{src_build_folder}", "&&",
      File.join(src_clone_folder,"configure"), opts.join(" "), "&&",
      "nice make -j#{@Processors.to_s}", "&&",
      inst_cmd
    ]
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( env: @env, cmd: cmds.join(" ") )
    # self.InstallSystemd()
    self.WriteInfo
  end

  def InstallSystemd
  sd_txt = \
%Q{[Unit]
Description=Emacs: the extensible, self-documenting text editor

[Service]
Type=forking
ExecStart=#{@prefix}/bin/emacs --daemon --user %u
ExecStop=#{@prefix}/bin/emacsclient --eval "(progn (setq kill-emacs-hook 'nil) (kill-emacs))"
Restart=always
User=%i
WorkingDirectory=%h

[Install]
WantedBy=multi-user.target
}
  
  systemd_dir = File.join(ENV["HOME"],'.config','systemd','user')
  FileUtils.mkdir_p(systemd_dir)
  File.write(File.join(systemd_dir, 'emacs.service'), sd_txt)
  
  inst_cmd = [
    "systemctl --user daemon-reload",
    "systemctl enable --user emacs",
    "systemctl start --user emacs",
  ]
  
  self.Run(cmd: inst_cmd)
  end

end # class InstEmacsNC
