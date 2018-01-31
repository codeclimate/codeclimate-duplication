# frozen_string_literal: true

require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Swift
        class Main < CC::Engine::Analyzers::Base
          PATTERNS = [
            "**/*.swift",
          ].freeze
          LANGUAGE = "swift"
          DEFAULT_MASS_THRESHOLD = 40
          DEFAULT_FILTERS = [
            "(ImportDeclaration ___)".freeze,
          ]
          POINTS_PER_OVERAGE = 10_000
          REQUEST_PATH = "/swift"

          def use_sexp_lines?
            false
          end

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
