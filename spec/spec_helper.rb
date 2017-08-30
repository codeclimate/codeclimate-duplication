require "bundler/setup"
require "flay"
require "tmpdir"
require "pry"
Pry.config.pager = false
Pry.config.color = false

require "cc/logger"

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

  config.order = :random
  config.disable_monkey_patching!

  config.filter_run focus: true
  config.alias_example_to :fit, focus: true
  config.alias_example_to :pit, pending: true
  config.run_all_when_everything_filtered = true
end

CC.logger.level = ::Logger::ERROR
