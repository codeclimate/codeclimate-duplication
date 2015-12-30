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
          BASE_POINTS = 1_500_000
          POINTS_PER_OVERAGE = 100_000
          TIMEOUT = 300

          def calculate_points(issue)
            BASE_POINTS + (overage(issue) * POINTS_PER_OVERAGE)
          end

          private

          def overage(issue)
            issue.mass - mass_threshold
          end

          def process_file(file)
            RubyParser.new.process(File.binread(file), file, TIMEOUT)
          end
        end
      end
    end
  end
end
