#!/usr/bin/env ruby

require_relative './fname_parser.rb'

# URL database interfacing part...
# --> JSON would be suffice, right?
#
# require 'hjson'
#
# class ParseHjson
#   def initialize(json_path='./')
#     json_fp = File.read(File.join(json_path, 'urls.json'))
#     @URL_DB = Hjson.parse(json_fp)
#   end
#
#   def GetURL(pkg_name)
#     return @URL_DB[pkg_name]
#   end
# end # class parse_json


##
## Due to deprecation of hjson on ruby platform(especially on newer ones),
## we decided to parse the json text by ourselves.
##

$def_db_json_name = 'urls.json'

require 'json'

class ParseHjson
  def initialize(json_path='../data/')

    # TODO: Gotta code this crap with more... parser like.
    @json_path = File.join(File.dirname(__FILE__), json_path)
    real_f_name = File.join(@json_path, $def_db_json_name)
    @json_data = File.readlines(real_f_name)
    @cleaned_up_data = []
    @json_data.each do |line|
      unless line.strip[0] == '#' or line.strip[0..1] == '//'
        cleaned_up_line = line.delete("\n").delete("\r").gsub(/( |(".*?"))/, "\\2")

        if cleaned_up_line.size > 0
          @cleaned_up_data.push(cleaned_up_line)
        end
      end
    end
    @cleaned_up_data = @cleaned_up_data.join('')
    @URL_DB = JSON.parse(@cleaned_up_data)
  end

  def GetDB(pkg_name)
    return @URL_DB[pkg_name]
  end

  def GetURL(pkg_name)
    return @URL_DB[pkg_name]["url"]
  end

  def GetType(pkg_name)
    return @URL_DB[pkg_name]["type"]
  end

  def GetScript(pkg_name)
    return @URL_DB[pkg_name]["script"]
  end

  def GetClass(pkg_name)
    return @URL_DB[pkg_name]["class"]
  end

  def GetInfo(pkg_name)
    return [ 
      self.GetURL(pkg_name), self.GetType(pkg_name),
      self.GetScript(pkg_name), self.GetClass(pkg_name) 
    ]
  end

  def GetPkgList()
    return @URL_DB.keys
  end

  def GetAltNames(pkg_name)
    return @URL_DB[pkg_name]["alt-names"]
  end

  def GetDepPkgs(pkg_name)
    return @URL_DB[pkg_name]["dependency"]
  end

end # class ParseHjson

# Some operator overloading alternatives.
module SRC_URL

  def [](pkg_name)
    begin
      json_parse = ParseHjson.new()
      return json_parse.GetURL(pkg_name)
    rescue
      puts "Not a valid package name: \"#{pkg_name}\""
      exit(-1)
    end
  end

  module_function :[]
end # module SRC_URL

module SRC_TYPE

  def [](pkg_name)
    begin
      json_parse = ParseHjson.new()
      return json_parse.GetType(pkg_name)
    rescue
      puts "[SRC_TYPE] Not a valid package name: \"#{pkg_name}\""
      exit(-1)
    end
  end

  module_function :[]
end # module SRC_TYPE

module SRC_SCRIPT

  def [](pkg_name)
    begin
      json_parse = ParseHjson.new()
      return json_parse.GetScript(pkg_name)
    rescue
      puts "[SRC_SCRIPT] Not a valid package name: \"#{pkg_name}\""
      exit(-1)
    end
  end

  module_function :[]
end # module SRC_SCRIPT

module SRC_CLASS

  def [](pkg_name)
    begin
      json_parse = ParseHjson.new()
      return json_parse.GetClass(pkg_name)
    rescue
      puts "[SRC_CLASS] Not a valid package name: \"#{pkg_name}\""
      exit(-1)
    end
  end

  module_function :[]
end # module SRC_CLASS


module SRC_INFO

  def [](pkg_name)
    begin
      json_parse = ParseHjson.new()
      return json_parse.GetInfo(pkg_name)
    rescue
      puts "[SRC_INFO] Not a valid package name: \"#{pkg_name}\""
      exit(-1)
    end
  end

  module_function :[]
end # module SRC_INFO

module SRC_VER

  def [](pkg_name)
    begin
      if pkg_name == 'golang'
        return ['git']
      end

      if pkg_name == 'tk'
        src_tarball_fname = SRC_URL['tk'].split('/')[-1]
        ver_str = src_tarball_fname.split('-')[0][2..-1]

        return Version.new(ver_str.split('.'))
      end

      if pkg_name == 'sqlite3'
        src_tarball_fname = SRC_URL['sqlite3'].split('/')[-1]
        src_tarball_bname = src_tarball_fname.split('.')[0]
        ver_str = src_tarball_bname.split('-')[-1]

        return Version.new([ ver_str[0], ver_str[1..2], ver_str[3..4] ].join('.'))
      end

      if pkg_name == 'pdflib'
        src_tarball_fname = SRC_URL['pdflib'].split('/')[-1]
        src_tarball_bname = src_tarball_fname.split('.')[0..-3].join('.')
        return Version.new(src_tarball_bname.split('-')[1])
      end

      if pkg_name == 'libjpeg'
        src_tarball_fname = SRC_URL['libjpeg'].split('/')[-1]
        return Version.new(src_tarball_fname.split('.')[-3].delete('v'))
      end

      if SRC_TYPE[pkg_name] == "tarball"
        fnp = FNParser.new(SRC_URL[pkg_name])
        src_ver = Version.new(fnp.version().join('.'))
      else
        src_ver = Version.new(SRC_TYPE[pkg_name])
      end

      return src_ver

    rescue
      puts "[SRC_VER] Not a valid package name: \"#{pkg_name}\""
      exit(-1)
    end
  end

  module_function :[]
end # module SRC_TYPE

module SRC_LIST

  def [](filter='')
    json_parse = ParseHjson.new()
    list = json_parse.GetPkgList()
    filtered_list = []
    unless filter.empty?
      list.each do |pkg|
        if pkg.include? filter
          filtered_list.append(pkg)
        end
      end
      return filtered_list
    else
      return list
    end
  end

  module_function :[]
end # mdoule SRC_LIST

module SRC_DEPS
  def [](pkg_name)
    begin
      json_parse = ParseHjson.new()
      return json_parse.GetDepPkgs(pkg_name)
    rescue
      puts "[SRC_DEPS] Not a valid package name: \"#{pkg_name}\""
      exit(-1)
    end
  end
  module_function :[]
end # module SRC_DEPS

module DB_PKG
  def [](pkg_name)
    begin
      json_parse = ParseHjson.new()
      return json_parse.GetDB(pkg_name)
    rescue
      puts "[DB_PKG] Not a valid package name: \"#{pkg_name}\""
      exit(-1)
    end
  end
  module_function :[]
end # module URL_DB

module TABLES
  def ALIAS_TABLE
    json_parse = ParseHjson.new()
    pkg_list = json_parse.GetPkgList()
    aliases_hash = {}
    
    pkg_list.each do |pkg|
      alt_pkg_names = json_parse.GetAltNames(pkg)
      unless alt_pkg_names.empty?
        alt_pkg_names.each do |apkg_n|
          aliases_hash[apkg_n] = pkg
        end
      end
    end

    return aliases_hash
  end # ALIAS_TABLE

  def DEP_TABLE
    json_parse = ParseHjson.new()
    pkg_list = json_parse.GetPkgList()
    dep_hash = {}

    pkg_list.each do |pkg|
      dep_hash[pkg] = json_parse.GetDepPkgs(pkg)
    end

    return dep_hash

  end # DEP_TABLE

  module_function :ALIAS_TABLE, :DEP_TABLE
end # module TABLES
