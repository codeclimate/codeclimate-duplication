require "cc/engine/analyzers/command_line_runner"

module CC
  module Engine
    module Analyzers
      module Javascript
        class Parser < ParserBase
          attr_reader :code, :filename, :syntax_tree

          def initialize(code, filename)
            @code = code
            @filename = filename
          end

          def parse
            runner = CommandLineRunner.new(js_command)
            runner.run(strip_shebang(code)) do |ast|
              @syntax_tree = parse_json(ast)
            end

            self
          end

          private

          def js_command
            file = File.expand_path(File.dirname(__FILE__)) + '/parser.js'
            ["node", file.to_s]
          end

          def strip_shebang(code)
            if code.start_with?('#!')
              code.lines.drop(1).join
            else
              code
            end
          end
        end
      end
    end
  end
end
