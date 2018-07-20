# frozen_string_literal: true

require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Php
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "php"
          PATTERNS = [
            "**/*.php",
          ].freeze
          DEFAULT_MASS_THRESHOLD = 75
          DEFAULT_FILTERS = [
            "(Stmt_Namespace ___)",
            "(Stmt_Use ___)",
            "(comments ___)",
          ].freeze
          POINTS_PER_OVERAGE = 35_000
          REQUEST_PATH = "/php"

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
