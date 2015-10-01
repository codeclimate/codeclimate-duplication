require 'flay'
require 'json'
require 'cc/engine/analyzers/helpers/main'

module CC
  module Engine
    module Analyzers
      module Ruby
        class Main
          include ::CC::Engine::Analyzers::Helpers

          def initialize(directory:, engine_config:, io:)
            @directory = directory
            @engine_config = engine_config || {}
            @io = io
          end

          def run
            flay = ::Flay.new(flay_options)
            flay.process(*analyzed_files)
          end

          private

          attr_reader :directory, :engine_config, :io

          def filter_files(files)
            return files if engine_config["exclude_paths"].nil?
            files - excluded_files
          end

          def mass_threshold
            engine_config.fetch('config', {}).fetch('ruby', {}).fetch('mass_threshold', 10)
          end

          def analyzed_files
            filter_files(::Flay.expand_dirs_to_files(directory))
          end
        end
      end
    end
  end
end

