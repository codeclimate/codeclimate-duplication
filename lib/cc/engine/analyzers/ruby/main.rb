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
          PATTERNS = [
            "**/*.rb",
            "**/*.rake",
            "**/Rakefile",
            "**/Gemfile",
            "**/*.gemspec",
          ].freeze
          DEFAULT_MASS_THRESHOLD = 18
          POINTS_PER_OVERAGE = 100_000
          TIMEOUT = 300

          private

          def process_file(file)
            RubyParser.new.process(File.binread(file), file, TIMEOUT)
          rescue Timeout::Error
            warn "TIMEOUT parsing #{file}. Skipping."
          rescue => e
            warn "ERROR parsing #{file}: #{e.class}: #{e.message}. Skipping"
          end
        end
      end
    end
  end
end
