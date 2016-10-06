require "cc/engine/analyzers/python/parser"
require "cc/engine/analyzers/python/node"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/file_list"
require "cc/engine/analyzers/analyzer_base"
require "flay"

module CC
  module Engine
    module Analyzers
      module Python
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "python"
          PATTERNS = ["**/*.py"]
          DEFAULT_MASS_THRESHOLD = 32
          POINTS_PER_OVERAGE = 50_000

          private

          def process_file(path)
            Node.new(parser(path).parse.syntax_tree, path).format
          end

          def parser(path)
            ::CC::Engine::Analyzers::Python::Parser.new(self, File.binread(path), path)
          end
        end
      end
    end
  end
end
