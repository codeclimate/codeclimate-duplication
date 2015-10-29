module CC
  module Engine
    module Analyzers
      class Base
        def initialize(engine_config:)
          @engine_config = engine_config
        end

        def run
          files.map do |file|
            begin
              process_file(file)
            rescue => ex
              $stderr.puts "Skipping file #{file} due to exception"
              $stderr.puts "(#{ex.class}) #{ex.message} #{ex.backtrace.join("\n")}"
            end
          end
        end

        def mass_threshold
          engine_config.mass_threshold_for(self.class::LANGUAGE) || self.class::DEFAULT_MASS_THRESHOLD
        end

        def base_points
          self.class::BASE_POINTS
        end

        private

        attr_reader :engine_config

        def process_file(path)
          raise NoMethodError.new("Subclass must implement `process_file`")
        end

        def files
          ::CC::Engine::Analyzers::FileList.new(
            engine_config: engine_config,
            default_paths: self.class::DEFAULT_PATHS,
            language: self.class::LANGUAGE
          ).files
        end
      end
    end
  end
end
