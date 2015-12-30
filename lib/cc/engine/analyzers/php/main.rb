require 'cc/engine/analyzers/php/parser'
require "cc/engine/analyzers/analyzer_base"
require 'flay'
require 'json'

module CC
  module Engine
    module Analyzers
      module Php
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "php"
          DEFAULT_PATHS = [
            "**/*.php",
            "**/*.inc",
            "**/*.module"
          ]

          private

          def process_file(path)
            code = File.binread(path)
            parser = php_parser.new(code, path).parse
            syntax_tree = parser.syntax_tree

            if syntax_tree
              syntax_tree.to_sexp
            end
          end

          def php_parser
            ::CC::Engine::Analyzers::Php::Parser
          end
        end
      end
    end
  end
end
