#!/usr/bin/env ruby

# this will handle Rust

# Rust installation is rather simple and their package system actually wants to use
# own directory at $HOME/.cargo. Therefore, we will not even list any source file.
#
# Also, the .info file will not contain any useful info. since every installation
# step is handled by the install system.

require_relative './install_stuff.rb'

require 'json'
require 'open3'

# Anyway, here's some useful tools to install
$rust_utils_to_install = [
  "exa", "bat", "rm-improved", "diskonaut", "lsd",
  "cargo-update", "starship", "tokei", "fd-find", "procs",
  "du-dust", "ripgrep", "hyperfine", "ytop", "zoxide",
  "gitui", "eureka", "ddh", "broot",
]

# The command installs rust with default option.
$rust_inst_cmd = "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"

class InstRust < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    @ver_check = false
    super(@pkgname, prefix=ENV["HOME"], @work_dirs, ver_check=@ver_check, verbose_mode=@verbose_mode)
    @rust_utils_to_install = $rust_utils_to_install
  end

  def do_install

    rustup_cmd = File.join(ENV["HOME"], '.cargo/bin/rustup')
    cargo_cmd = File.join(ENV["HOME"], '.cargo/bin/cargo')
    unless File.file?( rustup_cmd )
      # Installing the rust
      self.Run( $rust_inst_cmd, @pkgname )

      # path for cargo
      @rust_utils_to_install.each do |pkg|
        puts("Installing "+pkg)
        self.Run( ['nice', cargo_cmd, 'install', pkg].join(' ') )
      end
    else
      puts "Looks like the Rust is already installed!. Attempting to update"
      puts "Running rustup update"
      self.Run( ["source ~/.cargo/env && #{rustup_cmd} update"] )
      puts "Updating cargo packages"
      self.Run( ["source ~/.cargo/env && #{cargo_cmd} install-update -a"] )
      puts "Done working on Rust!"      
    end
    
    rustc_cmd = File.join(ENV["HOME"], '.cargo/bin/rustc')
    stdo, stde, stat = Open3.capture3("source ~/.cargo/env && #{rustc_cmd} --version")
    ver = stdo.split(" ")[1].split(".")
    @Version_Info = ver

    self.WriteInfo()

  end

  def WriteInfo
    puts "Writing package info for #{@pkgname}..."
    fp = File.open(@pkginfo_file, 'w')
    compile_info_json = {
      "Package Name" => @pkgname,
      "Install CMD" => $rust_inst_cmd,
      "Version" => @Version_Info,
      "Installed Files" => ["#{File.join(ENV["HOME"], '.cargo')}"]
    }
    fp.write(compile_info_json.to_json)
    fp.close
  end

end
