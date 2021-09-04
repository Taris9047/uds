#!/usr/bin/env ruby

require "etc"
require "fileutils"

require_relative "../utils/utils.rb"
require_relative "./install_stuff.rb"

$gcc_conf_options = [
  "--enable-languages=c,c++,fortran,objc,obj-c++",
  "--enable-shared",
  "--enable-default-pie",
  "--enable-linker-build-id",
  "--enable-threads=posix",
  "--enable-checking=release",
  "--enable-plugin",
  "--with-system-zlib",
  "--with-default-libstdcxx-abi=new",
  "--enable-objc-gc=auto",
  "--disable-multilib",
  "--disable-werror",
  "--build={target_arch}",
  "--host={target_arch}",
  "--target={target_arch}",
  "--libexecdir={prefix}/lib",
  "--libdir={prefix}/lib",
]

$gcc_latest_conf_options = [
  "--enable-languages=c,c++,fortran,objc,obj-c++",
  "--program-suffix=-11",
  "--enable-shared",
  "--enable-default-pie",
  "--enable-linker-build-id",
  "--enable-threads=posix",
  "--enable-checking=release",
  "--enable-plugin",
  "--with-system-zlib",
  "--with-default-libstdcxx-abi=new",
  "--enable-objc-gc=auto",
  "--disable-multilib",
  "--disable-werror",
  "--build={target_arch}",
  "--host={target_arch}",
  "--target={target_arch}",
  "--libexecdir={prefix}/lib",
  "--libdir={prefix}/lib",
]

$gcc_env = {
  "CC" => "gcc",
  "CXX" => "g++",
  "CFLAGS" => "-w -O3 -march=native -fomit-frame-pointer -pipe -fPIC",
  # "C_INCLUDE_PATH" => "{prefix}/include",
  "CXXFLAGS" => "-w -O3 -march=native -fomit-frame-pointer -pipe -fPIC",
# "CPLUS_INCLUDE_PATH" => "{prefix}/include",
# "LDFLAGS" => "-Wl,-rpath={prefix}/lib -Wl,-rpath={prefix}/lib64",
}

class InstGCC < InstallStuff
  def initialize(args)
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, ver_check = @ver_check, verbose_mode = @verbose_mode)

    @source_url = SRC_URL[@pkgname]
    @conf_options = $gcc_conf_options
    @env = $gcc_env
  end

  def get_env_str
    envstr = []
    @env.keys.each do |k|
      envstr += ["#{k}=\"#{@env[k]}\""]
    end
    return envstr.join(" ")
  end

  def install
    super
  end

  def do_install
    @pkginfo_file = File.join(@pkginfo_dir, @pkgname + ".info")
    @ver_source = SRC_VER["gcc"]

    if @pkgname == "gcc"
      if UTILS.which("gcc-#{@ver_source.major.to_s}")
        system_gcc = UTILS.which("gcc-#{@ver_source.major.to_s}")
      else
        system_gcc = UTILS.which("gcc")
      end
      ver_system_gcc = UTILS.get_system_gcc_ver(system_gcc)
      if ver_system_gcc >= @ver_source
        puts "Looks like system gcc is new enough! Skipping!"
        self.WriteInfo_system(ver_system_gcc.to_s)
        return 0
      end
    end

    # Replace '{prefix}' on configure parameters.
    @conf_options.each_with_index do |co, ind|
      if co.include? "{prefix}"
        @conf_options[ind] = co.gsub("{prefix}", @prefix)
      end
      if co.include? "{target_arch}"
        @conf_options[ind] = co.gsub("{target_arch}", @os_type)
      end
    end
    @env.each do |key, flag|
      if flag.include? "{prefix}"
        @env[key] = flag.gsub("{prefix}", @prefix)
      end
    end

    if File.file?(@pkginfo_file)
      puts "Oh, it seems gcc was already installed!! Skipping!!"
      return 0
    end

    puts "Downloading src from #{@source_url}"
    dl = Download.new(@source_url, @src_dir)
    source_file = dl.GetPath()
    fp = FNParser.new(source_file)
    src_tarball_fname, src_tarball_bname = fp.name

    extracted_src_dir = File.join(@build_dir, src_tarball_bname)
    bld_dir = extracted_src_dir + "-#{@pkgname}-build"
    @src_build_dir = bld_dir

    if Dir.exists?(extracted_src_dir)
      puts "Extracted folder has been found. Using it!"
    else
      puts "Extracting..."
      self.Run("tar xf " + source_file + " -C " + @build_dir)
    end

    # Downloading prerequisites
    puts "Downloading prerequisites ... "
    self.Run("cd " + File.realpath(extracted_src_dir) + " && " + "./contrib/download_prerequisites")

    # Let's build!!
    unless Dir.exists?(bld_dir)
      puts "Build dir missing... making one..."
    else
      puts "Build dir exists, cleaning up before work!!"
      FileUtils.rm_rf(bld_dir)
    end
    FileUtils.mkdir_p(bld_dir)

    if @need_sudo
      inst_cmd = "sudo -H make install"
    else
      inst_cmd = "make install"
    end

    opts = ["--prefix=" + @prefix] + @conf_options
    unless opts.include?("--disable-bootstrap")
      bootstrap_cmd = "nice make -j#{@Processors.to_s} bootstrap &&"
    else
      bootstrap_cmd = ""
    end
    cmd = [
      "cd #{File.realpath(bld_dir)}", "&&",
      File.join(File.realpath(extracted_src_dir), "configure"), opts.join(" "), "&&",
      bootstrap_cmd,
      "nice make -j#{@Processors.to_s}", "&&",
      inst_cmd,
    ]

    # Ok let's rock!
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall(env: @env, cmd: cmd.join(" "))
    self.WriteInfo
  end

  def WriteInfo_system(ver_system_gcc)
    puts "Writing package info for #{@pkgname}..."
    fp = File.open(@pkginfo_file, "w")
    env_str = @env.map { |k, v| "{k}={v}".gsub("{k}", k).gsub("{v}", v) }.join("\n")

    o, e, s = Open3.capture3("echo $(gcc -v)")
    conf_options_str = o

    fnp = FNParser.new(@source_url)
    compile_info_json = {
      "Package Name" => @pkgname,
      "Source file URL" => "system_package_manager",
      "Version" => ver_system_gcc.split("."),
      "Config options" => conf_options_str,
      "Env Variables" => "system_package_manager",
      "Installed Files" => ["refer system package manager!"],
    }
    fp.write(compile_info_json.to_json)
    # fp.puts(compile_info.join("\n"))
    fp.close
  end

  def ShowInstallInfo
    super
  end
end # class InstGCC

class InstGCCLatest < InstallStuff
  def initialize(args)
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(@pkgname, @prefix, @work_dirs, ver_check = @ver_check, verbose_mode = @verbose_mode)

    @source_url = SRC_URL[@pkgname]
    @conf_options = $gcc_latest_conf_options
    @env = $gcc_env
  end

  def get_env_str
    envstr = []
    @env.keys.each do |k|
      envstr += ["#{k}=\"#{@env[k]}\""]
    end
    return envstr.join(" ")
  end

  def install
    super
  end

  def do_install
    @pkginfo_file = File.join(@pkginfo_dir, @pkgname + ".info")
    @ver_source = SRC_VER["gcc"]

    # if @pkgname == 'gcc'
    #   if UTILS.which("gcc-#{@ver_source.major.to_s}")
    #     system_gcc = UTILS.which("gcc-#{@ver_source.major.to_s}")
    #   else
    #     system_gcc = UTILS.which("gcc")
    #   end
    #   ver_system_gcc = UTILS.get_system_gcc_ver(system_gcc)
    #   if ver_system_gcc >= @ver_source
    #     puts "Looks like system gcc is new enough! Skipping!"
    #     self.WriteInfo_system(ver_system_gcc.to_s)
    #     return 0
    #   end
    # end

    # Replace '{prefix}' on configure parameters.
    @conf_options.each_with_index do |co, ind|
      if co.include? "{prefix}"
        @conf_options[ind] = co.gsub("{prefix}", @prefix)
      end
      if co.include? "{target_arch}"
        @conf_options[ind] = co.gsub("{target_arch}", @os_type)
      end
    end
    @env.each do |key, flag|
      if flag.include? "{prefix}"
        @env[key] = flag.gsub("{prefix}", @prefix)
      end
    end

    if File.file?(@pkginfo_file)
      puts "Oh, it seems gcc was already installed!! Skipping!!"
      return 0
    end

    puts "Downloading src from #{@source_url}"
    dl = Download.new(@source_url, @src_dir)
    source_file = dl.GetPath()
    fp = FNParser.new(source_file)
    src_tarball_fname, src_tarball_bname = fp.name

    extracted_src_dir = File.join(@build_dir, src_tarball_bname)
    bld_dir = extracted_src_dir + "-#{@pkgname}-build"
    @src_build_dir = bld_dir

    if Dir.exists?(extracted_src_dir)
      puts "Extracted folder has been found. Using it!"
    else
      puts "Extracting..."
      self.Run("tar xf " + source_file + " -C " + @build_dir)
    end

    # Downloading prerequisites
    puts "Downloading prerequisites ... "
    self.Run("cd " + File.realpath(extracted_src_dir) + " && " + "./contrib/download_prerequisites")

    # Let's build!!
    unless Dir.exists?(bld_dir)
      puts "Build dir missing... making one..."
    else
      puts "Build dir exists, cleaning up before work!!"
      FileUtils.rm_rf(bld_dir)
    end
    FileUtils.mkdir_p(bld_dir)

    if @need_sudo
      inst_cmd = "sudo -H make install"
    else
      inst_cmd = "make install"
    end

    opts = ["--prefix=" + @prefix] + @conf_options
    unless opts.include?("--disable-bootstrap")
      bootstrap_cmd = "nice make -j#{@Processors.to_s} bootstrap &&"
    else
      bootstrap_cmd = ""
    end
    cmd = [
      "cd #{File.realpath(bld_dir)}", "&&",
      File.join(File.realpath(extracted_src_dir), "configure"), opts.join(" "), "&&",
      bootstrap_cmd,
      "nice make -j#{@Processors.to_s}", "&&",
      inst_cmd,
    ]

    # Ok let's rock!
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall(env: @env, cmd: cmd.join(" "))
    self.WriteInfo
  end

  def WriteInfo_system(ver_system_gcc)
    puts "Writing package info for #{@pkgname}..."
    fp = File.open(@pkginfo_file, "w")
    env_str = @env.map { |k, v| "{k}={v}".gsub("{k}", k).gsub("{v}", v) }.join("\n")

    o, e, s = Open3.capture3("echo $(gcc-#{@Version[0]} -v)")
    conf_options_str = o

    fnp = FNParser.new(@source_url)
    compile_info_json = {
      "Package Name" => @pkgname,
      "Source file URL" => "system_package_manager",
      "Version" => ver_system_gcc.split("."),
      "Config options" => conf_options_str,
      "Env Variables" => "system_package_manager",
      "Installed Files" => ["refer system package manager!"],
    }
    fp.write(compile_info_json.to_json)
    # fp.puts(compile_info.join("\n"))
    fp.close
  end

  def ShowInstallInfo
    super
  end
end # InstGCCLatest

class InstGCCJit < InstGCC
  def initialize(args)
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
    super(args)

    @pkgname = "gcc-jit"
    @source_url = SRC_URL[@pkgname]
    @prefix = File.join(@prefix, ".opt/#{@pkgname}")

    # @conf_options = \
    #   $gcc_conf_options \
    #   - ["--enable-languages=c,c++,fortran,objc,obj-c++"] \
    #   - ["--enable-shared"] \
    #   + ["--enable-languages=c,c++,jit"] \
    #   + ["--program-suffix=-jit"] \
    #   + ["--enable-host-shared"] \
    #   + ["--disable-bootstrap"]
    @conf_options = [
      "--enable-languages=c,c++,jit",
      "--program-suffix=-jit",
      "--enable-host-shared",
      "--disable-bootstrap",
      "--enable-checking=release",
      "--disable-multilib",
      "--enable-default-pie",
      "--libexecdir={prefix}/lib",
      "--libdir={prefix}/lib",
    ]
    # @env = $gcc_env.gsub('{prefix}', @prefix)
  end

  def do_install
    super
  end
end # class InstGCCJit

class InstGCC8 < InstGCC
  def initialize(args)
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
    super(args)

    @pkgname = "gcc8"
    @source_url = SRC_URL[@pkgname]
    @prefix = File.join(@prefix, ".opt/#{@pkgname}")

    @conf_options = $gcc_conf_options - ["--enable-languages=c,c++,fortran,objc,obj-c++"] \
      + ["--enable-languages=c,c++"] \
      + ["--program-suffix=-8"]

    @env = {
      "CC" => "gcc",
      "CXX" => "g++",
      "CFLAGS" => "-w -O3 -march=native -fomit-frame-pointer -pipe",
      "CXXFLAGS" => "-w -O3 -march=native -fomit-frame-pointer -pipe",
    # "LDFLAGS" => "-Wl,-rpath={prefix}/lib -Wl,-rpath={prefix}/lib64",
    }
  end

  def do_install
    super
  end
end # class InstGCC8

class InstGCC9 < InstGCC
  def initialize(args)
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
    super(args)

    @pkgname = "gcc9"
    @source_url = SRC_URL[@pkgname]
    @prefix = File.join(@prefix, ".opt/#{@pkgname}")

    @conf_options = $gcc_conf_options - ["--enable-languages=c,c++,fortran,objc,obj-c++"] \
      + ["--enable-languages=c,c++"] \
      + ["--program-suffix=-9"]

    @env = {
      "CC" => "gcc",
      "CXX" => "g++",
      "CFLAGS" => "-w -O3 -march=native -fomit-frame-pointer -pipe",
      "CXXFLAGS" => "-w -O3 -march=native -fomit-frame-pointer -pipe",
    # "LDFLAGS" => "-Wl,-rpath={prefix}/lib -Wl,-rpath={prefix}/lib64",
    }
  end

  def do_install
    super
  end
end # class InstGCC9

# Gcc4.8.5 --> matching version for cuda 6.5 (MBP 2008)
class InstGCC4 < InstGCC
  def initialize(args)
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(args)

    @pkgname = "gcc4"
    @source_url = SRC_URL[@pkgname]
    # Separating this gcc installation.
    @prefix = File.join(@prefix, ".opt/#{@pkgname}")
    @ver_source = SRC_VER[@pkgname]

    @conf_options = [
      "--enable-shared",
      "--disable-boostrap",
      "--enable-threads=posix",
      "--disable-nls",
      "--enable-default-pie",
      "--disable-multilib",
      "--enable-languages=c,c++",
      "--libdir={prefix}/lib",
      "--libexecdir={prefix}/lib",
      "--build={target_arch}",
      "--host={target_arch}",
      "--target={target_arch}",
      "--program-suffix=-4",
    ]

    @env = {
      "CC" => "gcc",
      "CXX" => "g++",
      "CFLAGS" => "-w -O2 -std=gnu89 -fgnu89-inline -fomit-frame-pointer -pipe",
      "CXXFLAGS" => "-w -O2 -std=gnu++11 -fomit-frame-pointer -pipe",
    # "LDFLAGS" => "-Wl,-rpath={prefix}/lib -Wl,-rpath={prefix}/lib64",
    }
  end

  def do_install
    @pkginfo_file = File.join(@pkginfo_dir, @pkgname + ".info")

    # Replace '{prefix}' on configure parameters.
    @conf_options.each_with_index do |co, ind|
      if co.include? "{prefix}"
        @conf_options[ind] = co.gsub("{prefix}", @prefix)
      end
      if co.include? "{target_arch}"
        @conf_options[ind] = co.gsub("{target_arch}", @os_type)
      end
    end
    @env.each do |key, flag|
      if flag.include? "{prefix}"
        @env[key] = flag.gsub("{prefix}", @prefix)
      end
    end

    if File.file?(@pkginfo_file)
      puts "Oh, it seems gcc was already installed!! Skipping!!"
      return 0
    end

    puts "Downloading src from #{@source_url}"
    dl = Download.new(@source_url, @src_dir)
    source_file = dl.GetPath()
    fp = FNParser.new(source_file)
    src_tarball_fname, src_tarball_bname = fp.name

    extracted_src_dir = File.join(@build_dir, src_tarball_bname)
    bld_dir = extracted_src_dir + "-build"
    @src_build_dir = bld_dir

    if Dir.exists?(extracted_src_dir)
      puts "Extracted folder has been found. Using it!"
    else
      puts "Extracting..."
      self.Run("tar xf " + source_file + " -C " + @build_dir)
    end

    unless Dir.exists?(@prefix)
      FileUtils.mkdir_p(@prefix)
    end

    # Downloading prerequisites
    puts extracted_src_dir
    self.Run("cd " + File.realpath(extracted_src_dir) + " && " + "./contrib/download_prerequisites")

    # Need to patch a few files.
    puts ""
    puts "Patching bugged files..."
    patch_cmd = [
      "sed -i -e 's/__attribute__/\\/\\/__attribute__/g' #{extracted_src_dir}/gcc/cp/cfns.h",
      "sed -i 's/struct ucontext/ucontext_t/g' #{extracted_src_dir}/libgcc/config/i386/linux-unwind.h",
      "sed -i '/#include <pthread.h>/a #include <signal.h>' #{extracted_src_dir}/libsanitizer/asan/asan_linux.cc",
      "sed -i 's/__res_state \\*statp = (__res_state\\*)state\\;/struct __res_state \\*statp = (struct __res_state\\*)state\\;/g' #{extracted_src_dir}/libsanitizer/tsan/tsan_platform_linux.cc",
    ]
    # end
    self.Run(patch_cmd.join(" && "))

    # Let's build!!
    unless Dir.exists?(bld_dir)
      puts "Build dir missing... making one..."
    else
      puts "Build dir exists, cleaning up before work!!"
      FileUtils.rm_rf(bld_dir)
    end
    FileUtils.mkdir_p(bld_dir)

    if @need_sudo
      inst_cmd = "sudo make install"
    else
      inst_cmd = "make install"
    end

    opts = ["--prefix=" + @prefix] + @conf_options
    cmd = [
      self.get_env_str,
      "cd #{File.realpath(bld_dir)}",
      "#{File.join(File.realpath(extracted_src_dir), "configure")} #{opts.join(" ")}",
      "nice make -j #{@Processors.to_s}",
      inst_cmd,
    ]

    brag_msg = %{
*** This is totally deprecated software! ***
*** If it breaks, it breaks... ***
*** (This package was added solely due to old cuda: 6.5) ***

*** If it breaks, try installing ... ***
 (Ubuntu) gcc-multilib libstdc++6:i386
 (RHEL) libstdc++.i686
*** But don't expect to be 100\% successful. ***
}
    puts brag_msg
    sleep(2)

    # Ok let's rock!
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall(env: @env, cmd: cmd.join(" && "))

    self.WriteInfo
  end
end # class InstGCC4

class InstGCC4Sen < InstGCC
  def initialize(args)
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    super(args)

    @pkgname = "gcc4-sentaurus"
    @source_url = SRC_URL[@pkgname]
    # Separating this gcc installation.
    @prefix = File.join(@prefix, ".opt/#{@pkgname}")
    @ver_source = SRC_VER[@pkgname]

    @conf_options = [
      "--enable-boostrap",
      "--enable-threads=posix",
      "--disable-checking",
      "--with-system-zlib",
      "--enable__cxa_atexit",
      "--disable-libunwind-exceptions",
      "--disable-gcj",
      "--enable-languages=c,c++,fortran",
      "--with-cpu=generic",
      "--libdir={prefix}/lib",
      "--libexecdir={prefix}/lib",
      "--build={target_arch}",
      "--host={target_arch}",
      "--target={target_arch}",
    ]

    @env = {
      "CC" => "gcc",
      "CXX" => "g++",
      "CFLAGS" => "-w -O2 -std=gnu89 -fgnu89-inline -fomit-frame-pointer -pipe",
      "CXXFLAGS" => "-w -O2 -std=gnu++11 -fomit-frame-pointer -pipe",
    # "LDFLAGS" => "-Wl,-rpath={prefix}/lib -Wl,-rpath={prefix}/lib64",
    }
  end

  def do_install
    @pkginfo_file = File.join(@pkginfo_dir, @pkgname + ".info")

    # Replace '{prefix}' on configure parameters.
    @conf_options.each_with_index do |co, ind|
      if co.include? "{prefix}"
        @conf_options[ind] = co.gsub("{prefix}", @prefix)
      end
      if co.include? "{target_arch}"
        @conf_options[ind] = co.gsub("{target_arch}", @os_type)
      end
    end
    @env.each do |key, flag|
      if flag.include? "{prefix}"
        @env[key] = flag.gsub("{prefix}", @prefix)
      end
    end

    if File.file?(@pkginfo_file)
      puts "Oh, it seems gcc was already installed!! Skipping!!"
      return 0
    end

    puts "Downloading src from #{@source_url}"
    dl = Download.new(@source_url, @src_dir)
    source_file = dl.GetPath()
    fp = FNParser.new(source_file)
    src_tarball_fname, src_tarball_bname = fp.name

    extracted_src_dir = File.join(@build_dir, src_tarball_bname)
    bld_dir = extracted_src_dir + "-build"
    @src_build_dir = bld_dir

    if Dir.exists?(extracted_src_dir)
      puts "Extracted folder has been found. Using it!"
    else
      puts "Extracting..."
      self.Run("tar xf " + source_file + " -C " + @build_dir)
    end

    unless Dir.exists?(@prefix)
      FileUtils.mkdir_p(@prefix)
    end

    # Downloading prerequisites
    puts extracted_src_dir
    self.Run("cd " + File.realpath(extracted_src_dir) + " && " + "./contrib/download_prerequisites")

    # Need to patch a few files.
    puts ""
    puts "Patching bugged files..."
    patch_cmd = [
      "sed -i -e 's/__attribute__/\\/\\/__attribute__/g' #{extracted_src_dir}/gcc/cp/cfns.h",
      "sed -i 's/struct ucontext/ucontext_t/g' #{extracted_src_dir}/libgcc/config/i386/linux-unwind.h",
      "sed -i '/#include <pthread.h>/a #include <signal.h>' #{extracted_src_dir}/libsanitizer/asan/asan_linux.cc",
      "sed -i 's/__res_state \\*statp = (__res_state\\*)state\\;/struct __res_state \\*statp = (struct __res_state\\*)state\\;/g' #{extracted_src_dir}/libsanitizer/tsan/tsan_platform_linux.cc",
    ]
    # end
    self.Run(patch_cmd.join(" && "))

    # Let's build!!
    unless Dir.exists?(bld_dir)
      puts "Build dir missing... making one..."
    else
      puts "Build dir exists, cleaning up before work!!"
      FileUtils.rm_rf(bld_dir)
    end
    FileUtils.mkdir_p(bld_dir)

    if @need_sudo
      inst_cmd = "sudo make install"
    else
      inst_cmd = "make install"
    end

    opts = ["--prefix=" + @prefix] + @conf_options
    cmd = [
      self.get_env_str,
      "cd #{File.realpath(bld_dir)}",
      "#{File.join(File.realpath(extracted_src_dir), "configure")} #{opts.join(" ")}",
      "nice make -j #{@Processors.to_s}",
      inst_cmd,
    ]

    brag_msg = %{
*** This is totally deprecated software! ***
*** If it breaks, it breaks... ***
*** (This package was added solely due to Sentaurus 2015 Version) ***

*** If it breaks, try installing ... ***
 (Ubuntu) gcc-multilib libstdc++6:i386
 (RHEL) libstdc++.i686
*** But don't expect to be 100\% successful. ***
}
    puts brag_msg
    sleep(2)

    # Ok let's rock!
    puts "Compiling (with #{@Processors} processors) and Installing ..."
    self.RunInstall(env: @env, cmd: cmd.join(" && "))

    self.WriteInfo
  end
end # class InstGCC4Sen
