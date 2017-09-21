# frozen_string_literal: true

require "cc/engine/analyzers/sexp_lines"
require "cc/engine/analyzers/violation_read_up"
require "digest"

module CC
  module Engine
    module Analyzers
      class Violation
        def initialize(language_strategy:, identical:, current_sexp:, other_sexps:)
          @language_strategy = language_strategy
          @identical = identical
          @current_sexp = current_sexp
          @other_sexps = other_sexps
        end

        def format
          {
            "type": "issue",
            "check_name": check_name,
            "description": description,
            "categories": ["Duplication"],
            "location": format_location,
            "remediation_points": calculate_points,
            "other_locations": format_other_locations,
            "content": content_body,
            "fingerprint": fingerprint,
            "severity": calculate_severity,
          }
        end

        def report_name
          "#{current_sexp.file}-#{current_sexp.line}"
        end

        def mass
          current_sexp.mass
        end

        def occurrences
          other_sexps.count
        end

        def total_occurrences
          occurrences + 1
        end

        def identical?
          @identical
        end

        def check_name
          "#{duplication_type}-code"
        end

        def fingerprint_check_name
          "#{duplication_type.capitalize} code"
        end

        private

        attr_reader :language_strategy, :other_sexps, :current_sexp

        def calculate_points
          @calculate_points ||= language_strategy.calculate_points(self)
        end

        def points_across_occurrences
          calculate_points * total_occurrences
        end

        def calculate_severity
          language_strategy.calculate_severity(points_across_occurrences)
        end

        def format_location
          format_sexp(current_sexp)
        end

        def format_other_locations
          other_sexps.map do |sexp|
            format_sexp(sexp)
          end
        end

        def format_sexp(sexp)
          lines = SexpLines.new(sexp)
          {
            "path": sexp.file.gsub(%r{^./}, ""),
            "lines": {
              "begin": lines.begin_line,
              "end": lines.end_line,
            },
          }
        end

        def content_body
          @_content_body ||= { "body": ViolationReadUp.new(mass).contents }
        end

        def fingerprint
          digest = Digest::MD5.new
          digest << current_sexp.file
          digest << "-"
          digest << current_sexp.mass.to_s
          digest << "-"
          digest << fingerprint_check_name
          digest.to_s
        end

        def duplication_type
          if identical?
            "identical"
          else
            "similar"
          end
        end

        def description
          "#{duplication_type.capitalize} blocks of code found in #{total_occurrences} locations. Consider refactoring."
        end
      end
    end
  end
end
