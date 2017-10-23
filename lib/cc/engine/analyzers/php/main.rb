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
            "(Stmt_Use ___)",
          ].freeze
          POINTS_PER_OVERAGE = 40_000
          REQUEST_PATH = "/php"
          COMMENT_MATCHER = Sexp::Matcher.parse("(_ (comments ___) ___)")

          def transform_sexp(sexp)
            delete_comments!(sexp)
          end

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

          def delete_comments!(sexp)
            sexp.search_each(COMMENT_MATCHER) { |node| node.delete_at(1) }
          end
        end
      end
    end
  end
end
