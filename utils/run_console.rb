#!/usr/bin/env ruby

require 'open3'
require 'securerandom'
require 'fileutils'
require 'tty-spinner'

class RunConsole

  def initialize(verbose: true, logf_dir: '', logf_name: '', title: '')
    @Verbose = verbose
    @def_env = { "CLICOLOR" => "1", "CLICOLOR_FORCE" => "1" }
    @title = ''

    if logf_dir.empty?
      curr_dir=File.expand_path(File.dirname(__FILE__))
      @logf_dir = File.join(curr_dir, '../workspace/log')
    else
      @logf_dir = logf_dir
      if !File.directory?(@logf_dir)
        FileUtils.mkdir_p(@logf_dir)
      end

      unless logf_name.empty?
        unless logf_name.end_with?'.log'
          logf_name = [logf_name, '.log'].join('')
        end
        @log_file_name = File.join(@logf_dir, logf_name)
      else
        tmp_name = [SecureRandom.hex(10), '.log'].join('')
        @log_file_name = File.join(@logf_dir, tmp_name)
      end
    end

    # if logf_name.empty?
    #   @log_file_name = ''
    # else
      # unless logf_name.end_with?'.log'
      #   logf_name = [logf_name, '.log'].join('')
      # end
    #   @log_file_name = File.join(@logf_dir, logf_name)
    # end
    
  end

  def __run_quiet( env, cmds, opts )
    spinner = TTY::Spinner.new("[Working] :title ... :spinner", format: :bouncing_ball, hide_cursor: true)
    spinner.update(title: @title)
    spinner.auto_spin
    o, e, s = Open3.capture3( env, cmds )
    spinner.stop('(done!)')

    unless @log_file_name.empty?
      unless File.file?(@log_file_name)
        fp = File.open(@log_file_name, 'w')
      else
        fp = File.open(@log_file_name, 'a')
      end
    end
    fp.puts(o)
    fp.close

    if !s.success?
      spinner.error("(Not this crap again!)")
      self.WhenCrapHappens(env, cmds)
    else
      spinner.success("(OK!)")
    end

    return 0
  end

  def __run_verbose( env, cmds, opts )
    o = []
    e = []
    s = ''

    cli_color_env = @def_env
    Open3.popen2e( cli_color_env.merge(env), cmds ) do |stdin, stdout_err, wait_thr|
      Thread.new do
        stdout_err.each do |l|
          puts l
          #stdout_err.flush
          o.append(l)
        end
      end
      stdin.close
      s = wait_thr.value
    end

    if opts.length() >= 1
      @log_file_name = File.join(@logf_dir, [opts[0], '.log'].join(''))
    end

    unless @log_file_name.empty?
      unless File.file?(@log_file_name)
        fp = File.open(@log_file_name, 'w')
      else
        fp = File.open(@log_file_name, 'a')
      end
      fp.puts(o.join("\n"))
      fp.close
    end

    if !s.success?
      self.WhenCrapHappens(env, cmds)
    end

    return 0
  end

  def WhenCrapHappens(env, cmds)
    puts ""
    puts "*** Execution ended with error! ***"
    puts " ENV:"
    env.keys.each do |k|
      puts " #{k}=#{env[k]},"
    end
    puts ""
    puts " Command:"
    puts " #{cmds}"
    puts ""
    unless @log_file_name.empty?
      puts "Check #{@log_file_name} for details..."
    end
    exit(-1)
  end

  def Run(*args)
    if args[0].class == Hash
      env = args[0]
      cmds = args[1]
      opts = Array(args[2..-1])
    elsif args[0].class == Array
      env = {}
      cmds = args[0].join(' ')
      opts = Array(args[1..-1])
    elsif args[0].class == String
      env = {}
      cmds = args[0]
      if args.length > 1
        opts = Array(args[1..-1])
      else
        opts = []
      end
    end

    if @Verbose
      self.__run_verbose(env, cmds, opts)
    else
      self.__run_quiet(env, cmds, opts)
    end

  end

end