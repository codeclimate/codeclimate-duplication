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

            status ||= handle_open3_race_condition(out)

            if status.success?
              yield out
            elsif err.lines.any? { |line| line.include?("timeout/Timeout.java") }
              raise Timeout::Error
            else
              raise ::CC::Engine::Analyzers::ParserError, "`#{command}` exited with code #{status.exitstatus}:\n#{err}"
            end
          end
        end

        private

        attr_reader :command, :timeout

        # Work around a race condition in JRuby's Open3.capture3 that can lead
        # to a nil status returned. We'll consider the process successful if it
        # produced output that can be parsed as JSON.
        #
        # https://github.com/jruby/jruby/blob/master/lib/ruby/stdlib/open3.rb#L200-L201
        #
        def handle_open3_race_condition(out)
          JSON.parse(out)
          NullStatus.new(true, 0)
        rescue JSON::ParserError
          NullStatus.new(false, 1)
        end

        NullStatus = Struct.new(:success, :exitstatus) do
          def success?
            success
          end
        end
      end
    end
  end
end

