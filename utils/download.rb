#!/usr/bin/env ruby

# Download url designated file to designated location

require 'open-uri'
require 'net/http'
require 'ruby-progressbar'

require_relative './run_console.rb'

class Download < RunConsole

  def initialize(
    url='', destination='./', 
    source_ctl='', mode='wget', 
    source_ctl_opts='')
    
    super()
    @URL = url
    @DEST = File.realpath(destination)
    @source_ctl = source_ctl.downcase
    @dn_mode = mode.downcase
    @src_ctl_opts = source_ctl_opts

    unless @URL
      raise "No valid URL given!!"
      exit(-1)
    end

    if @source_ctl == ''
      @outf_name = "#{@URL.split('/')[-1]}"
      @outf_path = File.join(@DEST, @outf_name)
      if @dn_mode == 'direct'
        direct_download
      elsif @dn_mode == 'wget'
        puts "Downloading with external wget"
        wget_download
      end
    elsif @source_ctl == 'git'
      @outf_name = @URL.split('/')[-1].split('.')[0..-2].join('.')
      @outf_path = File.join(@DEST, @outf_name)
      git_clone
    end
  end

  def direct_download
    if File.exists? @outf_path
      puts "File seems to be already downloaded!"
      return 0
    end

    pbar = ''
    fname = @URL.split('/')[-1]
    URI.open(@URL, "rb",
      :content_length_proc => lambda {|t|
        if t && 0 < t
          pbar = ProgressBar.create(title: fname, total:t, progress_mark: '█'.encode('utf-8'))
        end
      },
      :progress_proc => lambda {|s|
        pbar.progress = s if pbar
      }) do |page|
      File.open("#{@outf_path}", "wb") do |f|
        while chunk = page.read(1024)
          f.write(chunk)
        end
      end
    end

    # dn = URI.open(@URL)
    # IO.copy_stream( dn, @outf_path )
  end

  def wget_download
    if File.exists? @outf_path
      puts "File seems to be already downloaded!"
      return 0
    end

    wget_cmd = [
      "wget",
      @URL,
      "-O",
      @outf_path,
    ].join(' ')
    system( wget_cmd )
  end

  def git_clone
    if File.exists? @outf_path
      puts "Repository seems to be already downloaded!"
      return 0
    end
    puts "Cloning from #{@URL} into #{@DEST}"
    system( "cd #{@DEST} && git clone #{@URL} #{@src_ctl_opts}" )
  end

  def GetPath
    @outf_path
  end

end
