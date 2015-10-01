require 'posix/spawn'
require 'timeout'
require 'cc/engine/analyzers/javascript/ast'

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
            runner = CommandLineRunner.new(js_env, self)
            runner.run(strip_shebang(code))
            self
          end

          def on_success(output)
            parsed_json = JSON.parse(output, max_nesting: false)
            parsed_json.delete('sourceType')


            @syntax_tree = CC::Engine::Analyzers::Javascript::AST.json_to_ast(parsed_json, filename)
          end

          private

          def js_env
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
            POSIX::Spawn::TimeoutExceeded,
            SystemStackError
          ]

          def initialize(command, delegate)
            @command = command
            @delegate = delegate
          end

          def run(input, timeout = DEFAULT_TIMEOUT)
            Timeout.timeout(timeout) do
              child = ::POSIX::Spawn::Child.new(command, input: input, timeout: timeout)
              if child.status.success?
                output = block_given? ? yield(child.out) : child.out
                delegate.on_success(output)
              end

            end
          rescue *EXCEPTIONS
          end
        end
      end
    end
  end
end
