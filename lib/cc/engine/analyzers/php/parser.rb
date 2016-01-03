require "cc/engine/analyzers/command_line_runner"
require "cc/engine/analyzers/php/ast"
require "cc/engine/analyzers/php/nodes"

module CC
  module Engine
    module Analyzers
      module Php
        class Parser < ParserBase
          attr_reader :code, :filename, :syntax_tree

          def initialize(code, filename)
            @code = code
            @filename = filename
          end

          def parse
            runner = CommandLineRunner.new("php #{parser_path}")
            runner.run(code) do |output|
              json = parse_json(output)

              @syntax_tree = CC::Engine::Analyzers::Php::Nodes::Node.new.tap do |node|
                node.stmts = CC::Engine::Analyzers::Php::AST.json_to_ast(json, filename)
                node.node_type = "AST"
              end
            end

            self
          end

        private

          def parser_path
            relative_path = "../../../../../vendor/php-parser/parser.php"
            File.expand_path(
              File.join(File.dirname(__FILE__), relative_path)
            )
          end
        end
      end
    end
  end
end

