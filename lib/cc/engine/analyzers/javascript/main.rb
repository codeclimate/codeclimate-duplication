require "cc/engine/analyzers/javascript/parser"
require "cc/engine/analyzers/javascript/node"
require "cc/engine/analyzers/file_list"
require "flay"
require "json"

module CC
  module Engine
    module Analyzers
      module Javascript
        class Main
          LANGUAGE = "javascript"
          DEFAULT_PATHS = [
            "**/*.js",
            "**/*.jsx"
          ]
          DEFAULT_MASS_THRESHOLD = 40
          BASE_POINTS = 3000

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
            engine_config.mass_threshold_for(LANGUAGE) || DEFAULT_MASS_THRESHOLD
          end

          def base_points
            BASE_POINTS
          end

          private

          attr_reader :engine_config, :directory

          def process_file(path)
            Node.new(js_parser.new(File.read(path), path).parse.syntax_tree, path).format
          end

          def js_parser
            ::CC::Engine::Analyzers::Javascript::Parser
          end

          def files
            ::CC::Engine::Analyzers::FileList.new(
              directory: directory,
              engine_config: engine_config,
              default_paths: DEFAULT_PATHS,
              language: LANGUAGE
            ).files
          end
        end
      end
    end
  end
end
