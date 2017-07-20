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
          SCRUB_NODE_PROPERTIES = %w[start end]
          SCRUB_NODE_TYPES = %w[CommentBlock CommentLine]
        end
      end
    end
  end
end
