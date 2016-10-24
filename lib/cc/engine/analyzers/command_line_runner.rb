require "timeout"
require "spoon"
require "securerandom"

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
            file_actions = Spoon::FileActions.new
            id = SecureRandom.uuid

            # setup stdin
            file_actions.close(0)
            File.open("/tmp/#{id}.in", "w") { |f| f.write(input) }
            file_actions.open(0, "/tmp/#{id}.in", 0, 0600)

            # setup stdout
            file_actions.close(1)
            file_actions.open(1, "/tmp/#{id}.out", File::WRONLY | File::TRUNC | File::CREAT, 0600)

            # setup stderr
            file_actions.close(2)
            file_actions.open(2, "/tmp/#{id}.err", File::WRONLY | File::TRUNC | File::CREAT, 0600)

            spawn_attr = Spoon::SpawnAttributes.new

            cmd = ["env", command].flatten
            pid = Spoon.posix_spawnp("/usr/bin/env", file_actions, spawn_attr, cmd)
            Process.waitpid(pid)

            if (output = successful_output?(id))
              yield output
            else
              err = error_output(id)
              raise ::CC::Engine::Analyzers::ParserError, "`#{command}` did not produce valid JSON and printed this to stderr: #{err}"
            end
          end
        end

        private

        attr_reader :command, :timeout

        def successful_output?(id)
          output = File.read("/tmp/#{id}.out")
          JSON.parse(output, max_nesting: false) and output
        rescue JSON::ParserError
          nil
        end

        def error_output(id)
          File.read("/tmp/#{id}.err")
        end
      end
    end
  end
end
