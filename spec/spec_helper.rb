require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/unit'
require 'mocha/mini_test'
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

def read_up
  File.read('config/contents/duplicated_code.md')
end
