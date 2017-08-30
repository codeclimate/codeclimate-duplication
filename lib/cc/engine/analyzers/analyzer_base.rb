# frozen_string_literal: true

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

        BASE_POINTS = 1_500_000

        def initialize(engine_config:)
          @engine_config = engine_config
        end

        def run(file)
          if (skip_reason = skip?(file))
            CC.logger.info("Skipping file #{file} because #{skip_reason}")
            nil
          else
            process_file(file)
          end
        rescue => ex
          if RESCUABLE_ERRORS.map { |klass| ex.instance_of?(klass) }.include?(true)
            CC.logger.info("Skipping file #{file} due to exception (#{ex.class}): #{ex.message}\n#{ex.backtrace.join("\n")}")
            nil
          else
            CC.logger.info("#{ex.class} error occurred processing file #{file}: aborting.")
            raise ex
          end
        end

        def files
          file_list.files
        end

        def filters
          engine_config.filters_for(language)
        end

        def language
          self.class::LANGUAGE
        end

        def mass_threshold
          engine_config.mass_threshold_for(language) || self.class::DEFAULT_MASS_THRESHOLD
        end

        def count_threshold
          engine_config.count_threshold_for(language)
        end

        def calculate_points(mass)
          overage = mass - mass_threshold
          base_points + (overage * points_per_overage)
        end

        def transform_sexp(sexp)
          sexp
        end

        private

        attr_reader :engine_config

        def base_points
          self.class::BASE_POINTS
        end

        def points_per_overage
          self.class::POINTS_PER_OVERAGE
        end

        def process_file(_path)
          raise NoMethodError, "Subclass must implement `process_file`"
        end

        def file_list
          @_file_list ||= ::CC::Engine::Analyzers::FileList.new(
            engine_config: engine_config,
            patterns: engine_config.patterns_for(
              language,
              self.class::PATTERNS,
            ),
          )
        end

        def skip?(_path)
          nil
        end
      end
    end
  end
end
