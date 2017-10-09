# frozen_string_literal: true

require "cc/engine/analyzers/python/parser"
require "cc/engine/analyzers/python/node"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"
require "flay"

module CC
  module Engine
    module Analyzers
      module Python
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "python"
          PATTERNS = ["**/*.py"].freeze
          DEFAULT_MASS_THRESHOLD = 32
          DEFAULT_PYTHON_VERSION = 2
          POINTS_PER_OVERAGE = 50_000

          def transform_sexp(sexp)
            sexp.flatter
          end

          private

          def process_file(path)
            Node.new(parser(path).parse.syntax_tree, path).format
          end

          def parser(path)
            ::CC::Engine::Analyzers::Python::Parser.new(python_version, File.binread(path), path)
          end

          def python_version
            engine_config.fetch_language(LANGUAGE).fetch("python_version", DEFAULT_PYTHON_VERSION)
          end
        end
      end
    end
  end
end
