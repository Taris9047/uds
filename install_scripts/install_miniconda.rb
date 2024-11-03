#!/usr/bin/env ruby

# Miniconda install script...
# Using... official miniconda install script for Linux x86_64
#

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

class InstMiniconda < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]

    # Setting up compilers
    self.CompilerSet

  end

  def do_install

    puts ""
    puts "Working on #{@pkgname}"
    puts ""

    dl = Download.new(@source_url, @src_dir)
    src_path = dl.GetPath
    conda_install_path = File.join(ENV['HOME'], '.miniconda3')
    shell_name = `echo -e #{ENV['SHELL']}`.split('/')[-1].chomp

    # Ok let's roll!!
    cmds = [
      "chmod +x #{src_path}", "&&",
      "#{src_path}"
    ]

    puts "Running Miniconda installation script!!"
    self.Run("#{cmds.join(" ")} -b -p #{conda_install_path} -f")

    puts "Activating Conda"
    # Strangely, self.Run isn't possible here...
    system("#{conda_install_path}/etc/profile.d/conda.sh >> #{ENV['HOME']}/.bashrc")
    #system("eval \"$(#{conda_install_path}/bin/conda shell.#{shell_name} hook)\"")
    #system("conda init")
  end

end # class InstMiniconda
