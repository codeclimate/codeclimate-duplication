require "open3"
require "timeout"

module CC
  module Engine
    module Analyzers
      class CommandLineRunner
        DEFAULT_TIMEOUT = 300

        def initialize(command, timeout = DEFAULT_TIMEOUT)
          @command = command
          @timeout = timeout
        end

        def run(input)
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

        private

        attr_reader :command, :timeout
      end
    end
  end
end

