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
          ].freeze
          LANGUAGE = "javascript"
          DEFAULT_MASS_THRESHOLD = 40
          POINTS_PER_OVERAGE = 30_000

          private

          def process_file(path)
            Node.new(js_parser.new(File.read(path), path).parse.syntax_tree, path).format
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
