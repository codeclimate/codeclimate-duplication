# frozen_string_literal: true

require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module TypeScript
        class Main < CC::Engine::Analyzers::Base
          PATTERNS = [
            "**/*.ts",
          ]
          LANGUAGE = "typescript"
          DEFAULT_MASS_THRESHOLD = 45
          DEFAULT_FILTERS = [
            "(ImportDeclaration ___)",
            "(VariableDeclarator _ (init (CallExpression (_ (Identifier require)) ___)))",
          ]
          POINTS_PER_OVERAGE = 30_000
          REQUEST_PATH = "/typescript"

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
