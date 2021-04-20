#!/usr/bin/env ruby

# Let's set up compiler here

#$cflags = "-O3 -fno-semantic-interposition -march=native -fomit-frame-pointer -pipe"
#$cxxflags = "-O3 -fno-semantic-interposition -march=native -fomit-frame-pointer -pipe"

require_relative './src_urls.rb'
require_relative './misc_utils.rb'

$cflags = "-O3 -march=native -fomit-frame-pointer -pipe"
$cxxflags = $cflags
$include_path = '{env_path}/include'
$fallback_compiler_path = '/usr/bin'
$state_of_art_gcc_ver = SRC_VER['gcc'][0]

$rpath = "-Wl,-rpath=. -Wl,-rpath={env_path}/lib -Wl,-rpath={env_path}/lib64 -L{env_path}/lib -L{env_path}/lib64 -L/usr/lib -L/usr/lib64"
$pkg_config_path = "{env_path}/lib/pkgconfig:{env_path}/lib64/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/lib/pkgconfig"

class GetCompiler

  def initialize(
    cc_path: '/usr/bin', 
    cxx_path: '/usr/bin', 
    cflags: '', 
    cxxflags: '', 
    clang: false,
    suffix: nil,
    env_path: '',
    verbose: false)

    @fallback_compiler_path = '/usr/bin/'

    @current_gcc_major = SRC_VER['gcc'].major

    @CC_PATH = @fallback_compiler_path
    @CXX_PATH = @fallback_compiler_path
    @CFLAGS = [$cflags, cflags].join(' ')
    @RPATH = $rpath
    if ENV['PKG_CONFIG_PATH']
      @PKG_CONFIG_PATH = "#{$pkg_config_path}:#{ENV['PKG_CONFIG_PATH']}"
    else
      @PKG_CONFIG_PATH = "#{$pkg_config_path}"
    end
    @PATH=""
    @CXXFLAGS = [$cxxflags, cxxflags].join(' ')
    # @CC = File.join(@CC_PATH, "gcc-#{@current_gcc_major}")
    # @CXX = File.join(@CXX_PATH, "g++-#{@current_gcc_major}")
    @env_path = env_path

    @verbose = verbose

    @prefix = env_path
    if env_path == '' or !File.directory? env_path
      @prefix = File.dirname(cc_path)
    end
    @C_INCLUDE_PATH=$include_path.gsub('{env_path}', @prefix)
    @CPLUS_INCLUDE_PATH=@C_INCLUDE_PATH
    @CFLAGS += " -I#{@C_INCLUDE_PATH}"
    @CXXFLAGS += " -I#{@CPLUS_INCLUDE_PATH}"
    @CFLAGS = @CFLAGS.gsub('{env_path}', @prefix)
    @CXXFLAGS = @CFLAGS.gsub('{env_path}', @prefix)


    @RPATH = @RPATH.gsub('{env_path}', @prefix)
    unless @PKG_CONFIG_PATH.empty?
      @PKG_CONFIG_PATH = @PKG_CONFIG_PATH.gsub('{env_path}', @prefix)
    end

    if clang
      c_compiler = 'clang'
      cxx_compiler = 'clang++'
      # Clang already has -fno-semantic-interposition
      if @CFLAGS.include? '-fno-semantic-interposition'
        @CFLAGS.slice! '-fno-semantic-interposition'
      end
      if @CXXFLAGS.include? '-fno-semantic-interposition'
        @CXXFLAGS.slice! '-fno-semantic-interposition'
      end  
    else
      cc_state_of_art = UTILS.which("gcc-#{$state_of_art_gcc_ver}")
      cxx_state_of_art = UTILS.which("g++-#{$state_of_art_gcc_ver}")
      if cc_state_of_art and cxx_state_of_art
        c_compiler = cc_state_of_art
        cxx_compiler = cxx_state_of_art
      else
        c_compiler = UTILS.which("gcc")
        cxx_compiler = UTILS.which("g++")
      end
    end

    if suffix
      c_compiler_with_suffix = 'gcc' + '-' + suffix.to_s
      cxx_compiler_with_suffix = 'g++' + '-' + suffix.to_s
      if File.exist? c_compiler_with_suffix
        c_compiler = c_compiler_with_suffix
      end
      if File.exist? cxx_compiler_with_suffix
        cxx_compiler = cxx_compiler_with_suffix
      end
    end

    @CC = File.expand_path(c_compiler.strip)
    @CXX = File.expand_path(cxx_compiler.strip)

    unless File.exist?(@CC) or File.exist?(@CXX)
      puts "Detected C Compiler: #{@CC}, CXX Compiler: #{@CXX}"
      raise "Compiler toolset not found!!"
      exit(-1)
    end

    if @verbose
      puts "So, we're going to use those settings..."
      puts "C compiler: #{@CC}"
      puts "C++ compiler: #{@CXX}"
      puts "C flags: #{@CFLAGS}"
      puts "CXX flags: #{@CXXFLAGS}"
      puts "Linker flags: #{@RPATH}"
      unless @PKG_CONFIG_PATH.empty?
        puts "pkgconfig path: #{@PKG_CONFIG_PATH}"
      end
    end
  end

  def get_settings
    env_ary = [ "CC=\"#{@CC}\"" ] + \
      [ "CXX=\""+@CXX+"\"" ] + \
      [ "CFLAGS=\"#{@CFLAGS}\"" ] + \
      [ "CXXFLAGS=\"#{@CXXFLAGS}\"" ] + \
      [ "LDFLAGS=\"#{@RPATH}\"" ]
    
    unless @PKG_CONFIG_PATH.empty?
      env_ary += [ "PKG_CONFIG_PATH=\"#{@PKG_CONFIG_PATH}\"" ]
    end
    return env_ary
  end

  def get_env_str
    return self.get_settings.join(' ')
  end

  def get_env_settings
    env_hash = {
      'CC' => @CC,
      'CXX' => @CXX,
      'CFLAGS' => @CFLAGS,
      'CXXFLAGS' => @CXXFLAGS,
      'LDFLAGS' => @RPATH,
    }

    unless @PKG_CONFIG_PATH.empty?
      env_hash = env_hash.merge({ 'PKG_CONFIG_PATH' => @PKG_CONFIG_PATH })
    end
    return env_hash
  end

  def get_cmake_settings
    env_ary = [ "-DCMAKE_C_COMPILER=\""+@CC+"\"" ] + \
      [ "-DCMAKE_CXX_COMPILER=\""+@CXX+"\"" ] + \
      [ "-DCMAKE_C_FLAGS=\""+@CFLAGS+" "+@RPATH+"\"" ] + \
      [ "-DCMAKE_CXX_FLAGS=\""+@CXXFLAGS+" "+@RPATH+"\"" ] + \
      [ "-DCMAKE_EXE_LINKER_FLAGS_INIT=\""+@RPATH+"\"" ] + \
      [ "-DCMAKE_SHARED_LINKER_FLAGS_INIT=\""+@RPATH+"\"" ] + \
      [ "-DCMAKE_MODULE_LINKER_FLAGS_INIT=\""+@RPATH+"\"" ] + \
      [ "-DCMAKE_FIND_ROOT_PATH=#{@prefix}"]

    unless @PKG_CONFIG_PATH.empty?
      env_ary += [ "-DCMAKE_PKG_CONFIG_PATH=\"#{@PKG_CONFIG_PATH}\"" ]
    end
    return env_ary
  end

end
