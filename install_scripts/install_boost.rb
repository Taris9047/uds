#!/usr/bin/env ruby

# Installs Boost
# http://www.boost.org/

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

$b2_opts = [
  "address-model=64",
  "architecture=x86",
  "--build-dir=build",
  ]

class InstBoost < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    self.SrcURL(SRC_URL[@pkgname])
    @b2_opts = $b2_opts

    # Setting up compilers
    self.CompilerSet
  end

  def do_install

    puts "Downloading the source from #{@source_url}"
    dl = Download.new(@source_url, @src_dir)
    src_tarball_path = dl.GetPath

    fp = FNParser.new(@source_url)
    src_tarball_fname, src_tarball_bname = fp.name
    major, minor, patch = fp.version
    @@Version_Info = [major.to_s, minor.to_s, patch.to_s]

    src_extracted_folder = File.join(@build_dir,src_tarball_bname)
    @src_build_dir = src_extracted_folder
    if File.exists?(src_extracted_folder)
      puts "Previous Boost installation exists"
      puts "Using it."
    else
      self.Run( ["tar xvf", src_tarball_path, "-C", @build_dir].join(' ') )
    end

    # Boost is kinda simple. just build within the directory!
    if @need_sudo
      inst_cmd = "sudo ./b2 install"
    else
      inst_cmd = "./b2 install"
    end

    @b2_opts << "--prefix=#{@prefix}"
    @b2_opts << "stage"

    cmds = [
      "cd",
      src_extracted_folder, "&&",
      "./bootstrap.sh", "--prefix="+@prefix, "&&",
      "nice ./b2", @b2_opts.join(" "), "&&",
      inst_cmd
    ]

    @inst_cmd = cmds

    # Ok let's rock!
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall( env: @env, cmd: cmds.join(" ") )

    @conf_options = @b2_opts

    self.WriteInfo

  end # install

  def WriteInfo
    puts "Writing package info for #{@pkgname}..."
    fp = File.open(@pkginfo_file, 'w')
    compile_info_json = {
      "Package Name" => @pkgname,
      "Install ENV" => @env,
      "Install CMD" => @inst_cmd,
      "Config options" => @conf_options,
      "Version" => @@Version_Info,
      "Installed Files" => @Installed_files
    }
    fp.write(compile_info_json.to_json)
    fp.close    
  end

end # class InstBoost
