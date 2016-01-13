class URL
  property scheme, path, host
  property non_relative_flag
end

class Parser
  property url

  # https://url.spec.whatwg.org/
  def initialize(input)
    @url = URL.new
    @input = input.strip.to_unsafe
    @state = :scheme_start
    @buffer = String::Builder.new
    @at_flag = false
    @bracket_flag = false
    @ptr = 0
  end

  def c
    #begin
    @input[@ptr]
    #rescue IndexError
    #  '\0'
    #end
  end

  def run
    while @state
   #   p ({@ptr, @state, c})
      case @state
      when :scheme_start
        state_scheme_start
      when :scheme
        state_scheme
      when :path_or_authority
        state_path_or_authority
      when :authority
        state_authority
      when :host
        state_host
      else
        return
      end
      @ptr += 1
    end
  end

  def reset_buffer
    @buffer = String::Builder.new
  end

  def eos?
    c == '\0'
  end

  def special_scheme?
    %w(ftp file gopher http https ws wss).includes? url.scheme
  end

  def state_scheme_start
    if alpha?
      @state = :scheme
      @buffer << c.chr.downcase
    else
      @state = :no_scheme
      @ptr += 1
    end
  end

  def alpha?
    ('a'.ord <= c && c <= 'z'.ord) ||
      ('A'.ord <= c && c <= 'Z'.ord)
  end
  def state_scheme
    if alpha? || c == '-'.ord || c == '.'.ord || c == '+'.ord
      @buffer << c.chr
    elsif c == ':'.ord
      @url.scheme = @buffer.to_s
      reset_buffer
      # todo file and other special cases
      if @input[@ptr + 1] == '/'.ord
        @state = :path_or_authority
        @ptr += 1
      else
        @url.non_relative_flag = true
        @url.path = ""
        @state = :non_relative_path
      end
    else
      @state = :no_scheme
      @ptr = 0
    end
  end

  def state_path_or_authority
    if c == '/'.ord
      @state = :authority
    else
      @state = :path
    end
  end

  def state_authority
    if c == '@'.ord
      # todo
    elsif c == '\0'.ord || c == '/'.ord || c == '?'.ord || c == '#'.ord || (special_scheme? && c == '\\'.ord)
      @ptr -= @buffer.bytesize + 1
      reset_buffer
      @state = :host
    else
      @buffer << c.chr
    end
  end

  def state_host
    if c == ':'.ord && @bracket_flag == false
      # todo if url is special and buffer empty fail
      url.host = @buffer.to_s
      reset_buffer
      @state = :port
    elsif c == '\0'.ord || c == '/'.ord || c == '?'.ord || c == '#'.ord || (special_scheme? && c == '\\'.ord)
      @ptr -= 1
      # todo if url is special and buffer empty fail
      # todo host parsing buffer
      @url.host = @buffer.to_s
      reset_buffer
      @state = :path
    else
      @bracket_flag = true if c == '['.ord
      @bracket_flag = false if c == ']'.ord
      @buffer << c.chr
    end
  end
end

require "benchmark"
require "uri"

par = Parser.new("http://bitfission.com")
par.run
puts [par.url.scheme, par.url.host]

uri = URI.parse("http://bitfission.com")
puts [uri.scheme, uri.host]



Benchmark.ips do |x|
  x.report("new") { Parser.new("http://bitfission.com").run }
  x.report("old") { URI.parse("http://bitfission.com") }
end
