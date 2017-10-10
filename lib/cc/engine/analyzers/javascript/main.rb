# frozen_string_literal: true

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
          DEFAULT_MASS_THRESHOLD = 40
          DEFAULT_FILTERS = [
            "(ImportDeclaration ___)".freeze,
          ].freeze
          POINTS_PER_OVERAGE = 30_000
          REQUEST_PATH = "/javascript".freeze

          private

          def process_file(file)
            parse(file, REQUEST_PATH)
          end

          def default_filters
            DEFAULT_FILTERS.map { |filter| Sexp::Matcher.parse filter }
          end
        end
      end
    end
  end
end
