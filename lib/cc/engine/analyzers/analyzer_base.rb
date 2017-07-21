# frozen_string_literal: true

require "cc/parser"
require "cc/engine/analyzers/sexp_builder"

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
          build_sexp(node(file), file)
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

        protected

        def build_sexp(node, file)
          SexpBuilder.new(node, file).build
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
      end
    end
  end
end
