#!/usr/bin/env ruby
# this will handle emacs

# TODO: Implement more dependencies.
# 1. gnutls
# 2. giflib, libungif
# 3. jansson json parsor
# 4. libotf
# 5. m17n-flt
# 6. libxft
# 7. libgmp

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

class InstEmacs < InstallStuff

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

    @conf_options += [
      '--with-modules',
      '--with-xft',
      '--with-file-notification=inotify',
      '--with-x=yes',
      '--with-x-toolkit=gtk3',
      '--with-lcms2',
      '--with-json',
      '--with-imagemagick',
      '--with-gif=ifavailable',
      '--without-pop',
      '--with-mailutils',
      '--with-xwidgets'    # needs webkitgtk4-dev
    ]
    
    os_release_name=`grep -i 'name' /etc/*-release`
    if os_release_name.include? 'Red Hat' or
      os_release_name.include? 'CentOS' or
      os_release_name.include? 'Alma' or
      os_release_name.include? 'Rocky'
      @conf_options -= ['--with-imagemagick']
      @conf_options += ['--without-imagemagick']
      @env = {
        "CC" => UTILS.which("gcc"),
        "CFLAGS" => "-O3 -std=c99 -fomit-frame-pointer -march=native -pipe",
        "CPPFLAGS" => "-I#{@prefix}/include",
        "LDFLAGS" => "-L#{@prefix}/lib",
        "PKG_CONFIG_PATH" => "#{@prefix}/lib/pkgconfig:#{@prefix}/lib64/pkgconfig"
      }
    end
    
    puts @CC_VER.major
    if @CC_VER.major.to_i >= 11
      @env["CFLAGS"] = "-O3 -std=c99 -fomit-frame-pointer -march=native -pipe"
      @env["PKG_CONFIG_PATH"] = "#{@prefix}/lib/pkgconfig:#{@prefix}/lib64/pkgconfig"
    end

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
      self.Run( "rm -rf "+src_build_folder )
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
      "cd", src_extract_folder, "&&",
      "./autogen.sh", "&&",
      "cd", src_build_folder, "&&",
      src_extract_folder+"/configure",
      opts.join(" "), "&&",
      "nice make -j", @Processors.to_s, "&&",
      inst_cmd
    ]
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( env: @env, cmd: cmds.join(" ") )
    # self.InstallSystemd
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

end # class InstEmacs
