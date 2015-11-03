require 'timeout'

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
              IO.popen command, 'r+' do |io|
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
