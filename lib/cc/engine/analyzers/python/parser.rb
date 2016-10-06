require "cc/engine/analyzers/command_line_runner"
require "timeout"
require "json"

module CC
  module Engine
    module Analyzers
      module Python
        class Parser < ParserBase
          attr_reader :code, :filename, :syntax_tree

          def initialize(analyzer, code, filename)
            @analyzer = analyzer
            @code = code
            @filename = filename
          end

          def parse
            runner = CommandLineRunner.new(python_command)
            runner.run(code) do |ast|
              @syntax_tree = parse_json(ast)
            end

            self
          end

          private

          attr_reader :analyzer

          def python_command
            file = File.expand_path(File.dirname(__FILE__)) + '/parser.py'
            "#{python_binary} #{file}"
          end

          def python_binary
            "python2"
          end
        end
      end
    end
  end
end
