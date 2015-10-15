require "cc/engine/analyzers/python/parser"
require "cc/engine/analyzers/python/node"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/file_list"
require "flay"

module CC
  module Engine
    module Analyzers
      module Python
        class Main
          LANGUAGE = "python"
          DEFAULT_PATHS = ["**/*.py"]
          DEFAULT_MASS_THRESHOLD = 50

          def initialize(directory:, engine_config:)
            @directory = directory
            @engine_config = engine_config || {}
          end

          def run
            files.map do |file|
              process_file(file)
            end
          end

          def mass_threshold
            engine_config.fetch("config", {}).fetch("python", {}).fetch("mass_threshold", DEFAULT_MASS_THRESHOLD)
          end

          private

          attr_reader :directory, :engine_config

          def process_file(path)
            Node.new(::CC::Engine::Analyzers::Python::Parser.new(File.binread(path), path).parse.syntax_tree, path).format
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
