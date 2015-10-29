require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/unit'
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

def read_up
  File.read(read_up_path)
end

def read_up_path
  relative_path = "../config/contents/duplicated_code.md"
  File.expand_path(
    File.join(File.dirname(__FILE__), relative_path)
  )
end
