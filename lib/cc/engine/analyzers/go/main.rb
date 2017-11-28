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
          DEFAULT_MASS_THRESHOLD = 25
          DEFAULT_FILTERS = [
            "(ImportSpec ___)".freeze,
            "(File ___)".freeze,
            "(Comment ___)".freeze,
          ].freeze
          POINTS_PER_OVERAGE = 40_000
          REQUEST_PATH = "/go".freeze

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
