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

    cmds = [
      "git clone 'https://github.com/rbenv/rbenv.git' #{@rbenv_dir}",
      "git clone 'https://github.com/rbenv/ruby-build.git' #{File.join(@rbenv_dir, 'plugins', 'ruby-build')}",
      "PATH=#{@rbenv_dir}/bin:\$PATH rbenv install #{major}.#{minor}.#{patch}",
      "PATH=#{@rbenv_dir}/shims:\$PATH gem install #{$gems_to_install.join(' ')}"
    ]

    self.RunInstall( cmd: cmds.join(' && ') )

  end
end # class InstRuby
