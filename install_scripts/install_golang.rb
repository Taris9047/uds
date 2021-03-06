#!/usr/bin/env ruby

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

require 'open3'
require 'fileutils'

class InstGolang < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    @ver_check = false
    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)
    
    @source_url = SRC_URL[@pkgname]
    @bootstrap_url = SRC_URL['golang-bootstrap']
    @Version = SRC_VER[@pkgname].join('.')
  end

  def do_install

    puts "Bootstraping!!"
    self.Run( "cd #{@src_dir} && wget #{@bootstrap_url} -O ./golang-bootstrap.tgz" )
    self.Run( "cd #{@src_dir} && tar xvf ./golang-bootstrap.tgz")
    self.Run( {"CGO_ENABLED" => "0"}, "cd #{@src_dir}/go/src && ./make.bash")

    bootstrap_dir = File.join(@src_dir, "go")
    go_dir = File.join(@prefix, '.opt', 'go')

    puts "Let's build Golang version (#{@Version})"
    FileUtils.rm_rf("#{go_dir}")
    self.Run( "cd #{@src_dir} && git clone #{@source_url} #{go_dir} && cd #{go_dir} && git checkout go#{@Version}" )
    self.RunInstall( 
      env: {"GOROOT_BOOTSTRAP" => bootstrap_dir}, 
      cmd: "cd #{go_dir}/src && ./all.bash" )

    # self.WriteInfo

    golang_inst_mag = %Q(
Ok, golang has been installed!!
Make sure you add env stuff in your bashrc
GOPATH=#{go_dir}
Also, make sure to add #{go_dir}/bin to your PATH
)
    puts golang_inst_mag
    
  end

  def WriteInfo
    puts "Writing package info for #{@pkgname}..."
    fp = File.open(@pkginfo_file, 'w')
    compile_info_json = {
      "Package Name" => @pkgname,
      "Version" => $golang_version,
      "Installed Files" => @Installed_files,
    }
    fp.write(compile_info_json.to_json)
    fp.close
  end

end # class InstGolang
