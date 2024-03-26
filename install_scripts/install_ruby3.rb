#!/usr/bin/env ruby

# this will handle Ruby

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

$gems_to_install = [
    "rsense",
    "rails",
    "rake",
    "bundler",
    "open3",
    "json",
    "hjson",
    "ruby-progressbar",
    "tty-spinner",
    "lolcat"
]

class InstRuby3 < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]

    # Ruby modules to install
    @ruby_gems = $gems_to_install

    # Ruby build options
    @conf_options = []

    # Setting up compilers
    ruby_cflags = "-O3 -fomit-frame-pointer -fno-semantic-interposition -march=native -pipe"
    self.CompilerSet(
      cflags=ruby_cflags,
      cxxflags=ruby_cflags)

    @rbenv_dir = File.join(ENV["HOME"], '.rbenv')
    @prefix = @rbenv_dir

  end

  def do_install
    fp = FNParser.new(@source_url)
    src_tarball_fname, src_tarball_bname = fp.name
    major, minor, patch = fp.version

    if Dir.exist?(@rbenv_dir)
      puts "#{@rbenv_dir} exists! Trying to use existing rbenv!"
    else 
      rbenv_install_cmds = [
        "git clone 'https://github.com/rbenv/rbenv.git' #{@rbenv_dir}",
        "git clone 'https://github.com/rbenv/ruby-build.git' #{File.join(@rbenv_dir, 'plugins', 'ruby-build')}",
      ]
      self.RunInstall( cmd: rbenv_install_cmds.join(' && ') )
    end

    cmds = [
      "PATH=#{@rbenv_dir}/bin:\$PATH rbenv install #{major}.#{minor}.#{patch}",
      "PATH=#{@rbenv_dir}/bin:\$PATH rbenv global #{major}.#{minor}.#{patch}",
      "PATH=#{@rbenv_dir}/shims:\$PATH gem install #{$gems_to_install.join(' ')}"
    ]

    puts "Installing Ruby #{major}.#{minor}.#{patch} via rbenv!"
    self.RunInstall( cmd: cmds.join(' && ') )

    puts "Appending environment stuffs for rbenv."
    home_dir=ENV['HOME']
    bashrc=File.join(home_dir, '.bashrc')
    zshrc=File.join(home_dir, '.zshrc')
    
    if File.exist?(bashrc)
      if not File.readlines(bashrc).grep(/$("$HOME/.rbenv/bin/rbenv" init - bash)/)
        File.write(bashrc, 'eval "$("$HOME/.rbenv/bin/rbenv" init - bash)"', mode:'a+')
      end
    end
    if File.exist?(zshrc)
      if not File.readlines(zshrc).grep(/$("$HOME/.rbenv/bin/rbenv" init - zsh)/)
        File.write(zshrc, 'eval "$("$HOME/.rbenv/bin/rbenv" init - zsh)"', mode:'a+')
      end
    end
    # TODO: For mac... gotta check up with actual machine

  end
end # class InstRuby3
