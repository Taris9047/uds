#!/usr/bin/env ruby

# Packages to install:
# numpy scipy pandas sympy nose (matplotlib is currently doosh at this moment.)
#

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

require 'open3'

$pypy_modules = [
  'numpy', 'scipy', 'matplotlib',
  'pycparser', 'sympy', 'nose'
]

$pypy3_ver = '3.7'
$platform = 'x86_64'
$pypy_prefix_dir = '/.opt'

class InstPyPy3 < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    @ver_check = false
    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)

    @source_url = SRC_URL[@pkgname]
    @bootstrap_bin_url = DB_PKG[@pkgname]["bootstrap_bin_url"]
    @bootstrap_bin_tar = @bootstrap_bin_url.split('/')[-1]
    @bootstrap_bin_dirname = @bootstrap_bin_tar.split('.')[0..-3].join('.')
    @get_pip_url = SRC_URL['get_pip']

    # Python2 modules to install
    @pypy_modules = $pypy_modules
    @pypy3_ver = $pypy3_ver
    @platform = $platform
    @pypy_dest_dir = File.join(@prefix, $pypy_prefix_dir)

  end

  def do_install
    puts "*** Note that we cannot gaurantee if it will work or not."
    puts "*** If it fails, it fails!"

    puts "Downloading bootstrap binary."
    dn = Download.new(@bootstrap_bin_url, @src_dir)
    if !File.directory? @bootstrap_bin_dirname
      self.Run( "tar xvf #{File.join(@src_dir, @bootstrap_bin_tar)} -C #{@src_dir}/")
    end
    @bootstrap_bin = File.join(@src_dir, @bootstrap_bin_dirname, 'bin', 'pypy')

    puts "Cloning PyPy source from mercurial repo."
    if File.directory? File.join(@src_dir, 'pypy')
      self.Run( "cd #{File.join(@src_dir, 'pypy')} && hg update py#{@pypy3_ver}" )
    else
      self.Run( "cd #{@src_dir} && hg clone #{@source_url} pypy && cd ./pypy && hg update py#{@pypy3_ver}" )
    end

    pypy_src_dir = File.join(@src_dir, 'pypy')

    puts ""
    puts "Let's start the interpretation job. It will take pretty long time!"
    self.Run("cd #{pypy_src_dir}/pypy/goal && #{@bootstrap_bin} ../../rpython/bin/rpython --opt=jit && PYTHONPATH=../.. ./pypy3-c ../../lib_pypy/pypy_tools/build_cffi_imports.py")

    puts "Ok, let's package them!"
    so, se, stat = Open3.capture3("cd #{pypy_src_dir}/pypy/tool/release && #{@bootstrap_bin} ./package.py --archive-name=pypy-#{@pypy3_ver}-#{@platform}")

    archive_path = so.split('\n')[-1]

    puts "The pypy3 packages are located at #{archive_path}!!"
    puts "** A few remarks: **"
    puts "1. Do not put #{@pkgname} tarball into system directory. Put it somewhere isolated!"
    puts "2. Make sure resolve path problem manually if you added #{@pkgname}'s into your system PATH variable. It will install pip as pip3, same as python3's pip."
    puts "3. The #{@pkgname} currently based on python#{@pypy3_ver}. Make sure you do not have the same version of python3 or resolve collusion."
    puts "4. To install pip, just use pypy3 -mensurepip"
    pkgs_str = $pypy_modules.join(', ')
    puts "5. Currently we can install #{pkgs_str} without too much trouble. Other packages, we cannot be sure! If it breaks, it breaks at this moment."
    puts "****"
    puts ""

    self.WriteInfo

  end

  def WriteInfo
    puts "Writing package info for #{@pkgname}..."
    fp = File.open(@pkginfo_file, 'w')
    compile_info_json = {
      "Package Name" => @pkgname,
      "Version" => ["3", "7"]
    }
    fp.write(compile_info_json.to_json)
    fp.close
  end

end # class InstPyPy3
