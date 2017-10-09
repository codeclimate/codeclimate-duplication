# frozen_string_literal: true

require "flay"
require "json"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Java
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "java".freeze
          PATTERNS = ["**/*.java"].freeze
          DEFAULT_MASS_THRESHOLD = 40
          DEFAULT_FILTERS = [
            "(ImportDeclaration ___)".freeze,
            "(PackageDeclaration ___)".freeze,
          ].freeze
          POINTS_PER_OVERAGE = 10_000
          REQUEST_PATH = "/java".freeze

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
