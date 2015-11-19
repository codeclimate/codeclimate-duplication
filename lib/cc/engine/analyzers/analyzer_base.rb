module CC
  module Engine
    module Analyzers
      class Base
        def initialize(engine_config:)
          @engine_config = engine_config
        end

        def run(file)
          process_file(file)
        rescue => ex
          $stderr.puts "Skipping file #{file} due to exception"
          $stderr.puts "(#{ex.class}) #{ex.message} #{ex.backtrace.join("\n")}"
        end

        def files
          file_list.files
        end

        def mass_threshold_for_check(type)
          case type
          when :identical
            engine_config.identical_mass_threshold_for(self.class::LANGUAGE) || self.class::DEFAULT_MASS_THRESHOLDS.fetch(type)
          when :similar
            engine_config.similar_mass_threshold_for(self.class::LANGUAGE) || self.class::DEFAULT_MASS_THRESHOLDS.fetch(type)
          else
            raise ArgumentError.new("#{type} is not a valid check type")
          end
        end

        def base_points
          self.class::BASE_POINTS
        end

        private

        attr_reader :engine_config

        def process_file(path)
          raise NoMethodError.new("Subclass must implement `process_file`")
        end

        def file_list
          @_file_list ||= ::CC::Engine::Analyzers::FileList.new(
            engine_config: engine_config,
            default_paths: self.class::DEFAULT_PATHS,
            language: self.class::LANGUAGE
          )
        end
      end
    end
  end
end
