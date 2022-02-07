# frozen_string_literal: true

require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Javascript
        class Main < CC::Engine::Analyzers::Base
          PATTERNS = [
            "**/*.js",
            "**/*.jsx",
          ].freeze
          LANGUAGE = "javascript"
          DEFAULT_MASS_THRESHOLD = 45
          DEFAULT_FILTERS = [
            "(directives (:Directive (value (:DirectiveLiteral ___))))".freeze,
            "(:ImportDeclaration ___)".freeze,
            "(:VariableDeclarator _ (init (:CallExpression (_ (:Identifier require)) ___)))".freeze,
          ].freeze
          DEFAULT_POST_FILTERS = [
            "(:NUKE ___)".freeze,
            "(:Program _ ___)".freeze,
          ].freeze
          POINTS_PER_OVERAGE = 30_000
          REQUEST_PATH = "/javascript".freeze

          def use_sexp_lines?
            false
          end

          ##
          # Transform sexp as such:
          #
          #               s(:Program, :module, s(:body, ... ))
          #   => s(:NUKE, s(:Program, :module, s(:NUKE, ... )))

          def transform_sexp(sexp)
            return sexp unless sexp.body

            sexp.body.sexp_type = :NUKE # negate top level body
            sexp = s(:NUKE, sexp) # wrap with extra node to force full process

            sexp
          end

          protected

          def process_file(file)
            parse(file, self.class::REQUEST_PATH)
          end

          def default_filters
            self.class::DEFAULT_FILTERS.map { |filter| Sexp::Matcher.parse filter }
          end

          def default_post_filters
            self.class::DEFAULT_POST_FILTERS.map { |filter| Sexp::Matcher.parse filter }
          end
        end
      end
    end
  end
end
