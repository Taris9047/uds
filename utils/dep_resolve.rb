#!/usr/bin/env ruby

require_relative './download.rb'
require_relative './fname_parser.rb'
require_relative './get_compiler.rb'
require_relative './src_urls.rb'

require 'open3'
require 'json'

# Install order changer.

# Dependency table. -- It seems simple now...
$dependency_table = TABLES.DEP_TABLE

# class dependency resolve
# Simply put, re-orders the installation list according to the dependency table.
class DepResolve
  def initialize(
    install_list, pkginfo_dir,
    force_install=false, system_gcc=false,
    uninstall_mode=false)

    if install_list.empty?
      puts "No install list given! Exiting"
      exit(0)
    end

    # TODO: Update this part if package manager system changes...
    if File.directory? pkginfo_dir
      @Installed_pkg_list = \
        Dir.entries(pkginfo_dir).select { |f| f.include?('.info') }.map { |item| item.gsub('.info', '') }
    else
      @Installed_pkg_list = []
    end

    @use_system_gcc = system_gcc
    @force_install = force_install
    @pkginfo_dir = pkginfo_dir
    @uninstall_mode=uninstall_mode

    @Inst_list = install_list.uniq
    if !@force_install and !@Installed_pkg_list.empty? and !@uninstall_mode
      @Inst_list = self.remove_installed_pkg(@Inst_list)
    end

    if !@uninstall_mode
      @dep_list = self.__make_dep_list(@Inst_list)
      @Inst_list = (@dep_list+@Inst_list).uniq
    else
      @dep_list = []
    end

    if @use_system_gcc
      @dep_list.delete('gcc')
      @Inst_list.delete('gcc')
    end

  end # initialize

  def ver_chk_src_lte_ipkg(ipkg)
    src_ver = SRC_VER[ipkg]

    ipkg_txt = File.read(File.join(@pkginfo_dir, ipkg+'.info')).strip
    ipkg_info = JSON.parse(ipkg_txt)
    ipkg_ver = Version.new(ipkg_info["Version"].join('.'))

    if src_ver <= ipkg_ver
      return true
    else
      return false
    end
  end # def ver_chk_src_lte_ipkg(ipkg)

  # Removes package from Installed_pkg_list for re-installation.
  # --> if the package url is based on repo, it will always be
  # removed for freshness.
  # --> Basically, if someone updated url.json, the package will
  # be removed for re-installation with newer version.
  #
  def remove_installed_pkg(pkgs)

    if @Installed_pkg_list.empty?
      return pkgs
    end

    if pkgs.empty?
      return pkgs
    end

    marked_for_del = []
    pkgs = pkgs.uniq

    pkgs.each do |ipkg|
      if @Installed_pkg_list.include? ipkg
        # Golang is kind of fixed version case. But its explicit version
        # Isn't on the src file. So, skipping it if it's already installed.
        if ipkg == 'golang'
          marked_for_del.append('golang')
          next
        end

        unless SRC_TYPE[ipkg] == 'tarball'
          next
        end

        unless self.ver_chk_src_lte_ipkg(ipkg)
          next
        end

        marked_for_del.append(ipkg)
      end

    end # for

    pkgs -= marked_for_del
    return pkgs
  end # def remove_installed_pkg(ipkg)

  def __make_dep_list (inst_list)
    dep_list = []
    inst_list.each do |pkg|
      p_dep = $dependency_table[pkg]
      dep_list += p_dep
    end
    dep_list = dep_list.uniq
    dep_list = self.remove_installed_pkg(dep_list)

    # Checking out dependency list
    not_flat_dep_list = []
    dep_list.each do |pk|
      unless $dependency_table[pk].empty?
        not_flat_dep_list += [pk]
      end
    end
    not_flat_dep_list = not_flat_dep_list.uniq
    if !not_flat_dep_list.empty?
      return (self.__make_dep_list(not_flat_dep_list)+dep_list).uniq
    else
      return dep_list.uniq
    end
  end # def __make_dep_list

  def GetDepList
    return @dep_list
  end

  def GetInstList
    return @Inst_list
  end

  # TODO: Currently, it does autoremove not so needed libraries
  # But sometimes, having those libraries and programs might
  # not be that bad.
  #
  def GetUninstList
    # list_to_not_to_uninstall = []
    # @dep_list.each do |uninst|
    #   @Installed_pkg_list.each do |pkg|
    #     if SRC_DEPS[pkg].include?(uninst) or ['gcc','node','ruby','lua'].include?(uninst)
    #       list_to_not_to_uninstall += [uninst]
    #     end
    #   end
    # end
    # return @Inst_list - list_to_not_to_uninstall
    return @Inst_list - @dep_list
  end

  def PrintDepList
    if @dep_list.empty?
      return "Nothing!"
    else
      return @dep_list.join(" ")
    end
  end

  def PrintInstList
    if @Inst_list.empty?
      return "Nothing!"
    else
      return @Inst_list.join(" ")
    end
  end

end # class DepResolve
