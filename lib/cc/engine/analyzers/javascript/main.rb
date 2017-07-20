# frozen_string_literal: true

require "cc/engine/analyzers/analyzer_base"
require "cc/engine/analyzers/javascript/node_translator"

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
          REQUEST_PATH = "/javascript".freeze
          DEFAULT_MASS_THRESHOLD = 40
          POINTS_PER_OVERAGE = 30_000

          def translate_node(node, file)
            ::CC::Engine::Analyzers::Javascript::NodeTranslator.new(node, file).translate
          end
        end
      end
    end
  end
end
