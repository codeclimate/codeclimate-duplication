require "cc/engine/analyzers/javascript/parser"
require "cc/engine/analyzers/file_list"
require "flay"
require "json"

module CC
  module Engine
    module Analyzers
      module Javascript
        class Main
          DEFAULT_MASS_THRESHOLD = 10

          def initialize(engine_config:, directory:)
            @engine_config = engine_config
            @directory = directory
          end

          def run
            files.map do |file|
              process_file(file)
            end
          end

          def mass_threshold
            engine_config.fetch("config", {}).fetch("javascript", {}).fetch("mass_threshold", DEFAULT_MASS_THRESHOLD)
          end

          private

          attr_reader :engine_config, :directory

          def process_file(path)
            code = File.read(path)
            parser = js_parser.new(code, path).parse
            syntax_tree = parser.syntax_tree

            if syntax_tree
              syntax_tree.to_sexp
            end
          end

          def js_parser
            ::CC::Engine::Analyzers::Javascript::Parser
          end

          def files
            ::CC::Engine::Analyzers::FileList.new(
              directory: directory,
              engine_config: engine_config,
              extension: "js",
            ).files
          end
        end
      end
    end
  end
end
