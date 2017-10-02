# frozen_string_literal: true

require "cc/engine/analyzers/analyzer_base"
require "cc/engine/analyzers/javascript/parser"
require "cc/engine/analyzers/javascript/minification_checker"
require "cc/engine/analyzers/javascript/node"
require "cc/engine/analyzers/file_list"
require "flay"
require "json"

module CC
  module Engine
    module Analyzers
      module Javascript
        class Main < CC::Engine::Analyzers::Base
          PATTERNS = [
            "**/*.js",
            "**/*.jsx",
            "**/*.es",
            "**/*.es6",
          ].freeze
          LANGUAGE = "javascript"
          DEFAULT_MASS_THRESHOLD = 40
          POINTS_PER_OVERAGE = 30_000

          def transform_sexp(sexp)
            sexp.flatter
          end

          private

          def process_file(path)
            ast = js_parser.new(File.read(path), path).parse
            Node.new(ast.syntax_tree, path).format if ast
          end

          def js_parser
            ::CC::Engine::Analyzers::Javascript::Parser
          end

          def skip?(path)
            if MinificationChecker.new(path).minified?
              "the file is minified"
            end
          end
        end
      end
    end
  end
end
