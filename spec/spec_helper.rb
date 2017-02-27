require 'bundler/setup'
require 'flay'
require 'tmpdir'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.around(:example, :in_tmpdir) do |example|
    Dir.mktmpdir do |directory|
      @code = directory

      Dir.chdir(directory) do
        example.run
      end
    end
  end

  class DummyStderr
    def write(*)
    end

    def method_missing(*)
    end
  end

  unless ENV["ENGINE_DEBUG"]
    config.before(:each) do
      $stderr = DummyStderr.new
    end

    config.after(:each) do
      $stderr = STDERR
    end
  end

  config.order = :random
  config.disable_monkey_patching!
end
