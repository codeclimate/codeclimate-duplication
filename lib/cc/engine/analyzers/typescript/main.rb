# frozen_string_literal: true

require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module TypeScript
        class Main < CC::Engine::Analyzers::Base
          PATTERNS = [
            "**/*.ts",
            "**/*.tsx",
          ].freeze
          LANGUAGE = "typescript"
          DEFAULT_MASS_THRESHOLD = 45
          DEFAULT_FILTERS = [
            "(ImportDeclaration ___)".freeze,
            "(VariableDeclarator _ (init (CallExpression (_ (Identifier require)) ___)))".freeze,
          ].freeze
          POINTS_PER_OVERAGE = 30_000
          REQUEST_PATH = "/typescript".freeze

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
