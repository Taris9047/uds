#!/usr/bin/env ruby

# TODO: Need to handle alphabet based version number such as '6b'...
# Alpha <--> Numeric conversion classes
# Referenced: https://stackoverflow.com/questions/14632304/generate-letters-to-represent-number-using-ruby/31152792
# and https://stackoverflow.com/questions/10637606/doesnt-ruby-have-isalpha
#
class Numeric
  Alpha26 = ("a".."z").to_a
  def to_s26
    return "" if self < 1
    s, q = "", self
    loop do
      q, r = (q - 1).divmod(26)
      s.prepend(Alpha26[r]) 
      break if q.zero?
    end
    s
  end
end

class String
  Alpha26 = ("a".."z").to_a

  def to_i26
    result = 0
    downcased = downcase
    (1..length).each do |i|
      char = downcased[-i]
      result += 26**(i-1) * (Alpha26.index(char) + 1)
    end
    result
  end

  def isalpha?
    !match(/^[[:alnum:]]+$/)
  end
end

#
# Version handlig stuffs
# Referenced: https://stackoverflow.com/questions/2051229/how-to-compare-versions-in-ruby/2051427#2051427
#
class Version < Array
  @ver_string = ''
  @has_alphabet = false
  @alphabet_uppercase = false

  def initialize(s)
    if s.instance_of? String
      s = s.strip()
      begin
        # puts "#{s}: #{s[-1]}: #{s[-1].isalpha?}"
        if s[-1].isalpha?
          tmp = s[-1]
          s[-1] = '.'
          s += tmp.to_i26.to_s
          @has_alphabet = true
          if /[[:upper:]]/.match(tmp)
            @alphabet_uppercase = true
          end
        end
        super( s.split('.').map{ |e| e.delete(',').delete('v').delete('V').to_i } )
        @ver_string = self.join('.')
      rescue
        super([0,0,0])
        @ver_string = s
      end
    elsif s.instance_of? Array
      super( s.map{ |e| e.delete(',').delete('v').delete('V').to_i } )
      @ver_string = self.join('.')
    end
  end

  # Version comparison operators
  def <(x)
    (self <=> x) < 0
  end
  def <=(x)
    (self <=> x) <= 0
  end
  def >(x)
    (self <=> x) > 0
  end
  def >=(x)
    (self <=> x) >= 0
  end
  def ==(x)
    (self <=> x) == 0
  end

  # Returning the version info. from integer array to ...
  def to_s
    if @has_alphabet
      ver_str = self[0..-2].map{ |e| e.to_s }.join('.')
      unless @alphabet_uppercase
        ver_str += self[-1].to_s26
      else
        ver_str += self[-1].to_s26.upper
      end
      return ver_str
    else
      return self.map{ |e| e.to_s }.join('.')
    end
  end

  def to_sA
    if @has_alphabet
      ver_str = self[0..-2].map{ |e| e.to_s }.join('.')
      unless @alphabet_uppercase
        ver_str += self[-1].to_s26
      else
        ver_str += self[-1].to_s26.upcase
      end
      return ver_str.split('.')
    else
      return self.map{ |e| e.to_s }
    end
  end

  def major
    return self[0].to_s
  end

  def minor
    if self.length() > 1
      return self[1].to_s
    else
      return self[0].to_s
    end
  end

  def patch

    if @has_alphabet
      unless @alphabet_uppercase
        patch_str = [self[-2].to_s, self[-1].to_s26].join('')
      else
        patch_str = [self[-2].to_s, self[-1].to_s26.upcase].join('')
      end
      return patch_str
    else
      return self[-1].to_s
    end
  end

  def __alpha_to_int__
    
  end

end # class Version

#
# Some other misc utils
#
module UTILS

  # Which command eqv.
  # https://stackoverflow.com/a/5471032
  def which(cmd)
    if File.exist? cmd
      return cmd
    end
    
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      end
    end
    return nil
  end

  # Extracts system's GCC version - Returns as 
  def get_system_gcc_ver(system_gcc='gcc')
    o = `echo $(#{system_gcc} --version | grep ^gcc )`
    gcc_txt_ary = o.split(' ')
    gcc_ver_txt = ''
    gcc_txt_ary.each do |txt|
      if txt.split('.').length() == 3
        txt_split = txt.split('.')
        major = txt_split[0].to_i
        minor = txt_split[1].to_i
        patch = txt_split[2].to_i
        gcc_ver_txt = "#{major}.#{minor}.#{patch}"
        break
      end
    end
    ver_system_gcc = Version.new(gcc_ver_txt)
    return ver_system_gcc
  end

  module_function :which, :get_system_gcc_ver
end # module UTILS