require "flay"
require "json"
require "cc/engine/analyzers/reporter"

module CC
  module Engine
    module Analyzers
      module Ruby
        class Main
          DEFAULT_MASS_THRESHOLD = 10
          TIMEOUT = 10

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
            engine_config.fetch("config", {}).fetch("ruby", {}).fetch("mass_threshold", DEFAULT_MASS_THRESHOLD)
          end

          private

          attr_reader :directory, :engine_config

          def process_file(file)
            RubyParser.new.process(File.binread(file), file, TIMEOUT)
          end

          def files
            ::CC::Engine::Analyzers::FileList.new(
              directory: directory,
              engine_config: engine_config,
              extension: "rb",
            ).files
          end
        end
      end
    end
  end
end

