require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/unit'
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

def read_up
  File.read('config/contents/duplicated_code.md')
end
