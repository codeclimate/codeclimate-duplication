require 'cc/engine/analyzers/helpers/main'
require 'cc/engine/analyzers/python/parser'
require 'cc/engine/analyzers/python/node'
require 'flay'

module CC
  module Engine
    module Analyzers
      module Python
        class Main
          include ::CC::Engine::Analyzers::Helpers

          attr_reader :directory, :engine_config, :io

          def initialize(directory:, engine_config:, io:)
            @directory = directory
            @engine_config = engine_config || {}
            @io = io
          end

          def run
            files_to_analyze.each do |file|
              start_flay(process_file(file))
            end
          end

          def process_file(path)
            Node.new(::CC::Engine::Analyzers::Python::Parser.new(File.binread(path), path).parse.syntax_tree, path).format
          end

          def mass_threshold
            engine_config.fetch('config', {}).fetch('python', {}).fetch('mass_threshold', 50)
          end

          def start_flay(s_expressions)
            return if s_expressions.nil?
            flay.process_sexp(s_expressions)
          end

          def files_to_analyze
            files = Dir.glob("#{directory}/**/*.py").reject do |f|
              File.directory?(f)
            end

            files - excluded_files
          end
        end
      end
    end
  end
end
