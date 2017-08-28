# frozen_string_literal: true

require "flay"
require "json"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"
require "cc/engine/processed_source"
require "cc/engine/sexp_builder"

module CC
  module Engine
    module Analyzers
      module Java
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "java".freeze
          PATTERNS = ["**/*.java"].freeze
          DEFAULT_MASS_THRESHOLD = 40
          POINTS_PER_OVERAGE = 10_000
          REQUEST_PATH = "/java".freeze
          TIMEOUT = 300

          private

          def process_file(file)
            node = ProcessedSource.new(file, REQUEST_PATH).ast

            SexpBuilder.new(node, file).build
          end
        end
      end
    end
  end
end
