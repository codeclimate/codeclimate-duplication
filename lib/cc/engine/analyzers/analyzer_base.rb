# frozen_string_literal: true

require "cc/engine/analyzers/parser_error"
require "cc/engine/analyzers/parser_base"
require "cc/engine/analyzers/file_list"
require "cc/engine/processed_source"
require "cc/engine/sexp_builder"

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

        POINTS_PER_MINUTE = 10_000 # Points represent engineering time to resolve issue
        BASE_POINTS = 30 * POINTS_PER_MINUTE

        SEVERITIES = [
          MAJOR = "major".freeze,
          MINOR = "minor".freeze,
        ].freeze

        MAJOR_SEVERITY_THRESHOLD = 120 * POINTS_PER_MINUTE

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
          engine_config.filters_for(language) | default_filters
        end

        def language
          self.class::LANGUAGE
        end

        def check_mass_threshold(check)
          engine_config.mass_threshold_for(language, check) || self.class::DEFAULT_MASS_THRESHOLD
        end

        def mass_threshold
          engine_config.minimum_mass_threshold_for(language) || self.class::DEFAULT_MASS_THRESHOLD
        end

        def count_threshold
          engine_config.count_threshold_for(language)
        end

        def calculate_points(violation)
          overage = violation.mass - check_mass_threshold(violation.check_name)
          base_points + (overage * points_per_overage)
        end

        def calculate_severity(points)
          if points >= MAJOR_SEVERITY_THRESHOLD
            MAJOR
          else
            MINOR
          end
        end

        def transform_sexp(sexp)
          sexp
        end

        # Please see: codeclimate/app#6227
        def use_sexp_lines?
          true
        end

        private

        attr_reader :engine_config

        def base_points
          self.class::BASE_POINTS
        end

        def default_filters
          []
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

        def parse(file, request_path)
          processed_source = ProcessedSource.new(file, request_path)
          SexpBuilder.new(processed_source.ast, file).build
        rescue => ex
          handle_exception(processed_source, ex)
        end

        def handle_exception(processed_source, ex)
          CC.logger.debug { "Contents:\n#{processed_source.raw_source}" }

          case
          when ex.is_a?(CC::Parser::Client::HTTPError) && ex.response_status.to_s.start_with?("4")
            CC.logger.warn("Skipping #{processed_source.path} due to #{ex.class}")
            CC.logger.warn("Response status: #{ex.response_status}")
            CC.logger.debug { "Response:\n#{ex.response_body}" }
          when ex.is_a?(CC::Parser::Client::NestingDepthError)
            CC.logger.warn("Skipping #{processed_source.path} due to #{ex.class}")
            CC.logger.warn(ex.message)
          else
            CC.logger.error("Error processing file: #{processed_source.path}")
            CC.logger.error(ex.message)
            raise ex
          end
          nil
        end
      end
    end
  end
end
