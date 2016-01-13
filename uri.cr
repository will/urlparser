class Parser
  # https://url.spec.whatwg.org/
  def initialize(input)
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

  def state_scheme_start
    if current.alpha?
      @state = :scheme
      @buffer << current.lowercase
    else
      @state = :no_scheme
      @ptr += 1
    end
  end

  def state_scheme
    if current.alpha? || current == '-' || current == '.' || current == '+'
      @buffer << current
    elsif current == ':'
      # todo
    else
      @state = :no_scheme
    end
  end
end
