require "open3"
require "timeout"


module CC
  module Engine
    module Analyzers
      module Javascript
        class Parser
          attr_reader :code, :filename, :syntax_tree

          def initialize(code, filename)
            @code = code
            @filename = filename
          end

          def parse
            runner = CommandLineRunner.new(js_command, self)
            runner.run(strip_shebang(code)) do |ast|
              json_ast = JSON.parse(ast)
              @syntax_tree = json_ast
            end

            self
          end

          private

          def js_command
            file = File.expand_path(File.dirname(__FILE__)) + '/parser.js'
            "node #{file}"
          end

          def strip_shebang(code)
            if code.start_with?('#!')
              code.lines.drop(1).join
            else
              code
            end
          end
        end

        class CommandLineRunner
          attr_reader :command, :delegate

          DEFAULT_TIMEOUT = 20
          EXCEPTIONS = [
            StandardError,
            Timeout::Error,
            SystemStackError
          ]

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
