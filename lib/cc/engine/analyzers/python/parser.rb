require "timeout"
require "json"
require "open3"

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
              Open3.popen3 command, "r+" do |stdin, stdout, stderr, wait_thr|
                stdin.puts input
                stdin.close

                exit_code = wait_thr.value

                output = stdout.gets
                stdout.close

                err_output = stderr.gets
                stderr.close

                if 0 == exit_code
                  yield output
                else
                  raise ::CC::Engine::Analyzers::ParserError, "Python parser exited with code #{exit_code}:\n#{err_output}"
                end
              end
            end
          end
        end
      end
    end
  end
end
