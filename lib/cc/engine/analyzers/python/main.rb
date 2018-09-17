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

          def patterns
            case python_version
            when 2, "2"
              ["**/*.py"]
              "python2"
            when 3, "3"
              ["**/*.py", "**/*.py3"]
              "python3"
            else
              raise ArgumentError, "Supported python versions are 2 and 3. You configured: #{python_version.inspect}"
            end
          end
        end
      end
    end
  end
end
