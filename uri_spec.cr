require "./uri"
require "spec"

class TestParser < Parser
  macro cor(method)
    :{{method}}
  end
end

describe Parser, "scheme_start" do
  it "goes to if first char is alpha" do
    par = TestParser.new("h")
    par.state_scheme_start.should eq(:state_scheme)
  end
end

describe Parser, "scheme" do
  it "http" do
    par = Parser.new("http://bitfission.com")
    par.run
    par.url.scheme.should eq("http")
  end
end
