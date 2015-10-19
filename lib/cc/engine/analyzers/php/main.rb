require 'cc/engine/analyzers/php/parser'
require 'flay'
require 'json'

module CC
  module Engine
    module Analyzers
      module Php
        class Main
          LANGUAGE = "php"
          DEFAULT_PATHS = [
            "**/*.php",
            "**/*.inc",
            "**/*.module"
          ]
          DEFAULT_MASS_THRESHOLD = 10
          BASE_POINTS = 4_000

          attr_reader :directory, :engine_config, :io

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
            engine_config.mass_threshold_for(LANGUAGE) || DEFAULT_MASS_THRESHOLD
          end

          def base_points
            BASE_POINTS
          end

          private

          attr_reader :engine_config, :directory

          def process_file(path)
            code = File.read(path)
            parser = php_parser.new(code, path).parse
            syntax_tree = parser.syntax_tree

            if syntax_tree
              syntax_tree.to_sexp
            end
          end

          private

          def php_parser
            ::CC::Engine::Analyzers::Php::Parser
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
