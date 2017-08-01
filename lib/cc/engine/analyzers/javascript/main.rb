# frozen_string_literal: true

require "flay"
require "json"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"
require "cc/engine/analyzers/javascript/sexp_builder"

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

          def build_sexp(node, file)
            ::CC::Engine::Analyzers::Javascript::SexpBuilder.new(node, file).build
          end
        end
      end
    end
  end
end
