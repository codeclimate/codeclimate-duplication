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
            out, err, status = Open3.capture3(command, stdin_data: input)
            if status.success?
              yield out
            else
              raise ::CC::Engine::Analyzers::ParserError, "`#{command}` exited with code #{status.exitstatus}:\n#{err}"
            end
          end
        end

        private

        attr_reader :command, :timeout
      end
    end
  end
end

