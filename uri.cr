class URL
  property scheme, path
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
    @at_flag = nil
    @bracket_flag = nil
    @ptr = 0
  end

  def current
    @input[@ptr]
  end

  def run
    p ({@ptr, @state})
    case @state
    when :scheme_start
      state_scheme_start
    when :scheme
      state_scheme
    when :path_or_authority
      state_path_or_authority
    when :authority
      state_authority
    else
      return
    end
    @ptr += 1
    run
  end

  def read_and_reset_buffer
    val = @buffer.to_s
    @buffer = String::Builder.new
    val
  end

  def state_scheme_start
    if current.alpha?
      @state = :scheme
      @buffer << current.downcase
    else
      @state = :no_scheme
      @ptr += 1
    end
  end

  def state_scheme
    if current.alpha? || current == '-' || current == '.' || current == '+'
      @buffer << current
    elsif current == ':'
      @url.scheme = read_and_reset_buffer
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
    if current == '/'
      @state = :authority
    else
      @state = :path
    end
  end

  def state_authority
    if current == '@'
      # todo
      # elsif

    end
  end
end

par = Parser.new("http://bitfission.com")
par.run
p par.url
