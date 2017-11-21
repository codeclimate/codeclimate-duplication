# frozen_string_literal: true

require "flay"
require "json"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Go
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "go".freeze
          PATTERNS = ["**/*.go"].freeze
          DEFAULT_MASS_THRESHOLD = 45
          POINTS_PER_OVERAGE = 10_000
          REQUEST_PATH = "/go".freeze
          COMMENT_MATCHER = Sexp::Matcher.parse("(_ (comments ___) ___)")

          def use_sexp_lines?
            false
          end

          def transform_sexp(sexp)
            delete_comments!(sexp)
          end

          private

          def process_file(file)
            parse(file, REQUEST_PATH)
          end

          def delete_comments!(sexp)
            sexp.search_each(COMMENT_MATCHER) { |node| node.delete_at(1) }
          end
        end
      end
    end
  end
end
