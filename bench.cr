require "./uri"
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
