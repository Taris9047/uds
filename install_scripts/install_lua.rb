#!/usr/bin/env ruby

# Installs Lua

require 'fileutils'

require_relative '../utils/utils.rb'
require_relative './install_stuff.rb'

class InstLua < InstallStuff

  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
    super(@pkgname, @prefix, @work_dirs, @ver_check, @verbose_mode)
    
    @source_url = SRC_URL[@pkgname]
    @ver_maj_min = "#{SRC_VER[@pkgname].major}.#{SRC_VER[@pkgname].minor}"
    @version = SRC_VER[@pkgname].to_s

    @lua_pc = %Q(
V=#{@ver_maj_min}
R=#{@version}

prefix=#{@prefix}
INSTALL_BIN=$\{prefix\}/bin
INSTALL_INC=$\{prefix\}/include
INSTALL_LIB=$\{prefix\}/lib
INSTALL_MAN=$\{prefix\}/share/man/man1
INSTALL_LMOD=$\{prefix\}/share/lua/$\{V\}
INSTALL_CMOD=$\{prefix\}/lib/lua/$\{V\}
exec_prefix=$\{prefix\}
libdir=$\{exec_prefix\}/lib
includedir=$\{prefix\}/include

Name: Lua
Description: An Extensible Extension Language
Version: $\{R\}
Requires:
Libs: -L$\{libdir\} -llua -lm -ldl
Cflags: -I$\{includedir\}
)

    @patch = %q(diff -Naurp lua-5.4.0.orig/Makefile lua-5.4.0/Makefile
--- lua-5.4.0.orig/Makefile	2020-04-15 07:55:07.000000000 -0500
+++ lua-5.4.0/Makefile	2020-06-30 13:22:00.997938585 -0500
@@ -52,7 +52,7 @@ R= $V.0
 all:	$(PLAT)
 
 $(PLATS) help test clean:
-	@cd src && $(MAKE) $@
+	@cd src && $(MAKE) $@ V=$(V) R=$(R)
 
 install: dummy
 	cd src && $(MKDIR) $(INSTALL_BIN) $(INSTALL_INC) $(INSTALL_LIB) $(INSTALL_MAN) $(INSTALL_LMOD) $(INSTALL_CMOD)
diff -Naurp lua-5.4.0.orig/src/luaconf.h lua-5.4.0/src/luaconf.h
--- lua-5.4.0.orig/src/luaconf.h	2020-06-18 09:25:54.000000000 -0500
+++ lua-5.4.0/src/luaconf.h	2020-06-30 13:24:59.294932289 -0500
@@ -227,7 +227,7 @@
 
 #else			/* }{ */
 
-#define LUA_ROOT	"/usr/local/"
+#define LUA_ROOT	"/usr/"
 #define LUA_LDIR	LUA_ROOT "share/lua/" LUA_VDIR "/"
 #define LUA_CDIR	LUA_ROOT "lib/lua/" LUA_VDIR "/"
 
diff -Naurp lua-5.4.0.orig/src/Makefile lua-5.4.0/src/Makefile
--- lua-5.4.0.orig/src/Makefile	2020-04-15 08:00:29.000000000 -0500
+++ lua-5.4.0/src/Makefile	2020-06-30 13:24:15.746933827 -0500
@@ -7,7 +7,7 @@
 PLAT= guess
 
 CC= gcc -std=gnu99
-CFLAGS= -O2 -Wall -Wextra -DLUA_COMPAT_5_3 $(SYSCFLAGS) $(MYCFLAGS)
+CFLAGS= -fPIC -O0 -Wall -Wextra -DLUA_COMPAT_5_3 -DLUA_COMPAT_5_2 -DLUA_COMPAT_5_1 $(SYSCFLAGS) $(MYCFLAGS)
 LDFLAGS= $(SYSLDFLAGS) $(MYLDFLAGS)
 LIBS= -lm $(SYSLIBS) $(MYLIBS)
 
@@ -33,6 +33,7 @@ CMCFLAGS= -Os
 PLATS= guess aix bsd c89 freebsd generic linux linux-readline macosx mingw posix solaris
 
 LUA_A=	liblua.a
+LUA_SO=  liblua.so
 CORE_O=	lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o
 LIB_O=	lauxlib.o lbaselib.o lcorolib.o ldblib.o liolib.o lmathlib.o loadlib.o loslib.o lstrlib.o ltablib.o lutf8lib.o linit.o
 BASE_O= $(CORE_O) $(LIB_O) $(MYOBJS)
@@ -44,7 +45,7 @@ LUAC_T=	luac
 LUAC_O=	luac.o
 
 ALL_O= $(BASE_O) $(LUA_O) $(LUAC_O)
-ALL_T= $(LUA_A) $(LUA_T) $(LUAC_T)
+ALL_T= $(LUA_A) $(LUA_T) $(LUAC_T) $(LUA_SO)
 ALL_A= $(LUA_A)
 
 # Targets start here.
@@ -60,6 +61,12 @@ $(LUA_A): $(BASE_O)
 	$(AR) $@ $(BASE_O)
 	$(RANLIB) $@
 
+$(LUA_SO): $(CORE_O) $(LIB_O)
+	$(CC) -shared -ldl -Wl,--soname,$(LUA_SO).$(V) -o $@.$(R) $? -lm
+	$(MYLDFLAGS)
+	ln -sf $(LUA_SO).$(R) $(LUA_SO).$(V)
+	ln -sf $(LUA_SO).$(R) $(LUA_SO)
+
 $(LUA_T): $(LUA_O) $(LUA_A)
 	$(CC) -o $@ $(LDFLAGS) $(LUA_O) $(LUA_A) $(LIBS)
 
)

    # Setting up compilers
    self.CompilerSet

  end

  def do_install

    dl = Download.new(@source_url, @src_dir)
    # src_tarball_path = dl.GetPath

    fp = FNParser.new(@source_url)
    src_tarball_fname, src_tarball_bname = fp.name
    major, minor, patch = fp.version

    # puts src_tarball_fname, src_tarball_bname, major, minor, patch
    src_extract_folder = File.join(File.realpath(@build_dir), src_tarball_bname)

    if Dir.exists?(src_extract_folder)
      puts "Source file folder exists in "+src_extract_folder
      puts "Deleting ... "
      FileUtils.rm_rf(src_extract_folder)
    end

    puts "Extracting"
    self.Run(
      "tar xf "+File.realpath(File.join(@src_dir, src_tarball_fname))+" -C "+@build_dir )
    puts "Writing pkgconfig file for lua..."
    File.write(File.join(src_extract_folder, 'lua.pc'), @lua_pc, mode: 'w')
    puts "Writing shared library installation script for lua..."
    File.write(File.join(@build_dir, 'lua-shared.patch'), @patch, mode: 'w')

    puts "Installing Lua!!"
    install_cmd = [
      "nice make",
      "INSTALL_TOP=\"#{@prefix}\"",
      "INSTALL_DATA=\"cp -d\"",
      "TO_LIB=\"liblua.so liblua.so.#{@ver_maj_min} liblua.so.#{@version}\"",
      "install",
    ].join(' ')

    if @need_sudo
      sudo_cmd = 'sudo -H'
    else
      sudo_cmd = ''
    end

    # Ok let's roll!!
    cmds = [
      "cd", src_extract_folder,
      "&&", "patch -Np1 -i #{File.join(@build_dir, 'lua-shared.patch')}",
      "&&", "make CFLAGS=\"#{@env["CFLAGS"]} -fPIC\" LDFLAGS=\"#{@env["LDFLAGS"]}\" linux",
      "&&", sudo_cmd, "mkdir -pv #{@prefix}/lib/pkgconfig",
      "&&", sudo_cmd, install_cmd,
      "&&", sudo_cmd, "install -v -m644 -D lua.pc #{@prefix}/lib/pkgconfig/lua.pc",
    ]
    self.RunInstall( env: @env, cmd: cmds.join(" ") )
    self.WriteInfo
  end

end # class InstLua
