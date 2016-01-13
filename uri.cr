class URL
  property scheme, path, host
  property non_relative_flag
end

class Parser
  property url

  # https://url.spec.whatwg.org/
  def initialize(input)
    @url = URL.new
    @input = input.strip
    @state = :scheme_start
    @buffer = String::Builder.new
    @at_flag = false
    @bracket_flag = false
    @ptr = 0
  end

  def c
    begin
      @input[@ptr]
    rescue IndexError
      '\0'
    end
  end

  def run
    while @state
      p ({@ptr, @state, c})
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
    if c.alpha?
      @state = :scheme
      @buffer << c.downcase
    else
      @state = :no_scheme
      @ptr += 1
    end
  end

  def state_scheme
    if c.alpha? || c == '-' || c == '.' || c == '+'
      @buffer << c
    elsif c == ':'
      @url.scheme = @buffer.to_s
      reset_buffer
      # todo file and other special cases
      if @input[@ptr + 1] == '/'
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
    if c == '/'
      @state = :authority
    else
      @state = :path
    end
  end

  def state_authority
    if c == '@'
      # todo
    elsif c == '\0' || c == '/' || c == '?' || c == '#' || (special_scheme? && c == '\\')
      @ptr -= @buffer.bytesize + 1
      reset_buffer
      @state = :host
    else
      @buffer << c
    end
  end

  def state_host
    if c == ':' && @bracket_flag == false
      # todo if url is special and buffer empty fail
      url.host = @buffer.to_s
      reset_buffer
      @state = :port
    elsif c == '\0' || c == '/' || c == '?' || c == '#' || (special_scheme? && c == '\\')
      @ptr -= 1
      # todo if url is special and buffer empty fail
      # todo host parsing buffer
      @url.host = @buffer.to_s
      reset_buffer
      @state = :path
    else
      @bracket_flag = true if c == '['
      @bracket_flag = false if c == ']'
      @buffer << c
    end
  end
end

par = Parser.new("http://bitfission.com")
par.run
p par.url
