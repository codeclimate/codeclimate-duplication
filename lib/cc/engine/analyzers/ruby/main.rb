require "flay"
require "json"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Ruby
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "ruby"
          DEFAULT_PATHS = [
            "**/*.rb",
            "**/*.rake",
            "**/Rakefile",
            "**/Gemfile",
            "**/*.gemspec"

          ]
          DEFAULT_MASS_THRESHOLD = 18
          BASE_POINTS = 10_000
          TIMEOUT = 10

          private

          attr_reader :directory, :engine_config

          def process_file(file)
            RubyParser.new.process(File.binread(file), file, TIMEOUT)
          end
        end
      end
    end
  end
end

