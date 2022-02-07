# frozen_string_literal: true

require "flay"
require "json"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Csharp
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "csharp".freeze
          PATTERNS = ["**/*.cs"].freeze
          DEFAULT_MASS_THRESHOLD = 60
          DEFAULT_FILTERS = [
            "(:UsingDirective ___)".freeze
          ].freeze
          POINTS_PER_OVERAGE = 10_000
          REQUEST_PATH = "/csharp".freeze

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
