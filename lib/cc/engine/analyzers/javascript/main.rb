require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Javascript
        class Main < CC::Engine::Analyzers::Base
          PATTERNS = [
            "**/*.js",
            "**/*.jsx",
          ].freeze
          LANGUAGE = "javascript"
          REQUEST_PATH = "/javascript"
          DEFAULT_MASS_THRESHOLD = 40
          POINTS_PER_OVERAGE = 30_000
          SCRUB_NODE_PROPERTIES = ["start", "end"].freeze
        end
      end
    end
  end
end
