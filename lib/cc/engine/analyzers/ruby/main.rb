# frozen_string_literal: true

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
          DEFAULT_MASS_THRESHOLD = 25
          BASE_POINTS = 150_000
          POINTS_PER_OVERAGE = 20_000
          TIMEOUT = 300

          private

          def process_file(file)
            RubyParser.new.process(File.binread(file), file, TIMEOUT)
          rescue Timeout::Error
            CC.logger.warn("TIMEOUT parsing #{file}. Skipping.")
          end
        end
      end
    end
  end
end
