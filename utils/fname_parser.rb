#!/usr/bin/env ruby

require_relative './misc_utils.rb'

# Filename parser
# Only works with XXXX-X.X.X.ext1.ext2 or XXXX_X.X.X.ext1.ext2 format

class FNParser
  @@fname = nil
  @@bname = nil
  @@version = nil

  # Initializer
  def initialize(fname_url)

    if !fname_url
      puts "FNParser: Wrong URL given!"
      puts fname_url
      exit(-1)
    end

    @repo_addr = false
    if fname_url.include?('.git')
      @repo_addr = true
    else
      @@fname = File.basename fname_url

      split_f = @@fname.split(".")
      if @@fname.include?".tar."
        split_f.pop
        split_f.pop
        @@bname = split_f.join(".")
      else
        split_f.pop
        @@bname = split_f.join(".")
      end
    end
  end

  # Returns whole file name and without extension.
  def name()
    unless @repo_addr
      fn = @@fname
      bn = @@bname
      return [fn, bn]
    else
      return ['', '']
    end
  end

  # Returns version
  def version()

    # In case of Sqlite3... weird file naming convention it has...
    if @@fname.include?'sqlite-autoconf'
      fn_split = @@bname.split('-')
      ver_str = fn_split[-1].split('.')[0]
      ver_split = [ver_str[0], ver_str[1..2], ver_str[3..4]].join('.')
      @@version = Version.new(ver_split)
      return @@version.to_sA
    end

    if @repo_addr
      @@version = Version.new('0.0.0')
    else
      if @@bname.include?'_'
        # In case of boost
        delim = '_'

        tmp = @@bname.split(delim)
        ver_split = tmp[1..-1]
      else
        # In case of many other stuffs
        delim = '-'
        bname_split = @@bname.split(delim)[-1]
        ver_split = bname_split.split('.')
      end
      @@version = Version.new(ver_split.join('.'))
    end
    return @@version.to_sA
  end # def version()

end # class fnParser
