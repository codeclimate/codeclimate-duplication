# frozen_string_literal: true

require "cc/parser"
require "cc/engine/analyzers/node_translator"

module CC
  module Engine
    module Analyzers
      class Base
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
          translate_node(node(file), file)
        rescue => ex
          if ex.is_a?(CC::Parser::Client::HTTPError)
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

        def count_threshold
          engine_config.count_threshold_for(self.class::LANGUAGE)
        end

        def calculate_points(mass)
          overage = mass - mass_threshold
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

        protected

        def translate_node(node, file)
          NodeTranslator.new(node, file).translate
        end

        private

        attr_reader :engine_config

        def base_points
          self.class::BASE_POINTS
        end

        def points_per_overage
          self.class::POINTS_PER_OVERAGE
        end

        def node(file)
          CC::Parser.parse(
            File.binread(file),
            self.class::REQUEST_PATH,
          )
        end

        def file_list
          @_file_list ||= ::CC::Engine::Analyzers::FileList.new(
            engine_config: engine_config,
            patterns: engine_config.patterns_for(
              self.class::LANGUAGE,
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
