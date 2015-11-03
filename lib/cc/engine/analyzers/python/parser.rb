require 'timeout'
require 'json'

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
            runner = CommandLineRunner.new(python_command, self)
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

        class CommandLineRunner
          DEFAULT_TIMEOUT = 20

          attr_reader :command, :delegate

          def initialize(command, delegate)
            @command = command
            @delegate = delegate
          end

          def run(input, timeout = DEFAULT_TIMEOUT)
            Timeout.timeout(timeout) do
              IO.popen command, "r+" do |io|
                io.puts input
                io.close_write

                output = io.gets
                io.close

                yield output if $?.to_i == 0
              end
            end
          end
        end
      end
    end
  end
end
