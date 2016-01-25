require "cc/engine/analyzers/parser_error"
require "cc/engine/analyzers/parser_base"

module CC
  module Engine
    module Analyzers
      class Base
        RESCUABLE_ERRORS = [
          ::CC::Engine::Analyzers::ParserError,
          ::Errno::ENOENT,
          ::Racc::ParseError,
          ::RubyParser::SyntaxError,
          ::RuntimeError,
        ].freeze

        def initialize(engine_config:)
          @engine_config = engine_config
        end

        def run(file)
          process_file(file)
        rescue => ex
          if RESCUABLE_ERRORS.map { |klass| ex.instance_of?(klass) }.include?(true)
            $stderr.puts("Skipping file #{file} due to exception (#{ex.class}): #{ex.message}\n#{ex.backtrace.join("\n")}")
          else
            $stderr.puts("#{ex.class} error occurred processing file #{file}: aborting.")
            raise ex
          end
        end

        def files
          file_list.files
        end

        def mass_threshold
          engine_config.mass_threshold_for(self.class::LANGUAGE) || self.class::DEFAULT_MASS_THRESHOLD
        end

        def calculate_points(mass)
          self.class::BASE_POINTS * mass
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
