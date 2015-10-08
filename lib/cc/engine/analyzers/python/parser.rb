require 'posix/spawn'
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
              child = ::POSIX::Spawn::Child.new(command, input: input, timeout: timeout)

              if child.status.success?
                yield child.out if block_given?
              end
            end
          end
        end
      end
    end
  end
end
