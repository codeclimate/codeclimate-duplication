# frozen_string_literal: true

require "cc/engine/analyzers/command_line_runner"
require "timeout"
require "json"

module CC
  module Engine
    module Analyzers
      module Python
        class Parser < ParserBase
          attr_reader :code, :filename, :syntax_tree

          def initialize(python_version, code, filename)
            @python_version = python_version
            @code = code
            @filename = filename
          end

          def parse
            runner = CommandLineRunner.new(python_command)
            runner.run(code) do |ast|
              @syntax_tree = parse_json(ast)
            end

            self
          end

          private

          attr_reader :python_version

          def python_command
            file = File.expand_path(File.dirname(__FILE__)) + "/parser.py"
            "#{python_binary} #{file}"
          end

          def python_binary
            case python_version
            when 2, "2"
              "python2"
            when 3, "3"
              "python3"
            else
              raise ArgumentError, "Supported python versions are 2 and 3. You configured: #{python_version.inspect}"
            end
          end
        end
      end
    end
  end
end
