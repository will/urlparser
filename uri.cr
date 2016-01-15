class URL
  property scheme, path, host
  property non_relative_flag
end

class Parser
  property url

  SPECIAL_SCHEME = Set{"ftp", "file", "gopher", "http", "https", "ws", "wss"}

  macro cor(method)
    {{method}}
  end

  # https://url.spec.whatwg.org/
  def initialize(input)
    @url = URL.new
    @input = input.strip.to_unsafe
    @state = :scheme_start
    @at_flag = false
    @bracket_flag = false
    @ptr = 0
  end

  def c
    @input[@ptr]
  end

  def run
    state_scheme_start
  end

  def reset_buffer
    @buffer = String::Builder.new
  end

  def special_scheme?
    SPECIAL_SCHEME.includes? url.scheme
  end

  def state_scheme_start
    if alpha?
      cor state_scheme
    else
      # @state = :no_scheme
    end
  end

  def alpha?
    ('a'.ord <= c && c <= 'z'.ord) ||
      ('A'.ord <= c && c <= 'Z'.ord)
  end

  def state_scheme
    start = @ptr
    loop do
      if alpha? || c === '-' || c === '.' || c === '+'
        @ptr += 1
      elsif c === ':'
        @url.scheme = String.new(@input + start, @ptr - start)
        # todo file and other special cases
        if @input[@ptr + 1] === '/'
          @ptr += 1
          state_path_or_authority
        else
          @url.non_relative_flag = true
          @url.path = ""
          # @state = :non_relative_path
        end

        break
      else
        # @state = :no_scheme
        @ptr = 0
        break
      end
    end
  end

  def state_path_or_authority
    if c === '/'
      @ptr += 1
      state_authority
    else
      # @state = :path
    end
  end

  def state_authority
    @ptr += 1
    start = @ptr
    loop do
      if c === '@'
        # todo
      elsif c === '\0' || c === '/' || c === '?' || c === '#' || (special_scheme? && c === '\\')
        @ptr = start
        state_host
        break
      else
        @ptr += 1
      end
    end
  end

  def state_host
    start = @ptr
    loop do
      if c === ':' && @bracket_flag == false
        # todo if url is special and buffer empty fail
        @url.host = String.new(@input + start, @ptr - start)
        break
        # @state = :port
      elsif c === '\0' || c === '/' || c === '?' || c === '#' || (special_scheme? && c === '\\')
        # todo if url is special and buffer empty fail
        # todo host parsing buffer
        @url.host = String.new(@input + start, @ptr - start)
        break
        # @state = :path
      else
        @bracket_flag = true if c === '['
        @bracket_flag = false if c === ']'
        @ptr += 1
      end
    end
  end
end
