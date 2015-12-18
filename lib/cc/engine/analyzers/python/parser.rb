require "cc/engine/analyzers/command_line_runner"
require "timeout"
require "json"

module CC
  module Engine
    module Analyzers
      module Python
        class Parser
          attr_reader :code, :filename, :syntax_tree

          def initialize(code, filename)
            @code = code
            @filename = filename
          end

          def parse
            runner = CommandLineRunner.new(python_command)
            runner.run(code) do |ast|
              json_ast = JSON.parse(ast)
              @syntax_tree = json_ast
            end

            self
          end

          def python_command
            file = File.expand_path(File.dirname(__FILE__)) + '/parser.py'
            "python #{file}"
          end
        end
      end
    end
  end
end
