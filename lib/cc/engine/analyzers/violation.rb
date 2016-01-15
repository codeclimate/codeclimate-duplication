require "cc/engine/analyzers/sexp_lines"
require "cc/engine/analyzers/violation_read_up"
require "digest"

module CC
  module Engine
    module Analyzers
      class Violation
        attr_reader :issue

        def initialize(language_strategy, issue, hashes)
          @language_strategy = language_strategy
          @issue = issue
          @hashes = hashes
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
            "fingerprint": fingerprint
          }
        end

        def report_name
          "#{current_sexp.file}-#{current_sexp.line}"
        end

        private

        attr_reader :language_strategy, :hashes

        def current_sexp
          @location ||= sorted_hashes.first
        end

        def sorted_hashes
          @_sorted_hashes ||= hashes.sort_by(&:file)
        end

        def other_sexps
          @other_locations ||= sorted_hashes.drop(1)
        end

        def check_name
          if issue.identical?
            "Identical code"
          else
            "Similar code"
          end
        end

        def calculate_points
          language_strategy.calculate_points(issue)
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
            "path": sexp.file.gsub(%r(^./), ""),
            "lines": {
              "begin": lines.begin_line,
              "end": lines.end_line,
            },
          }
        end

        def content_body
          @_content_body ||= { "body": ViolationReadUp.new(issue).contents }
        end

        def fingerprint
          digest = Digest::MD5.new
          digest << current_sexp.file
          digest << "-"
          digest << current_sexp.mass.to_s
          digest << "-"
          digest << occurrences.to_s
          digest.to_s
        end

        def description
          description = "#{check_name} found in #{occurrences} other location"
          description += "s" if occurrences > 1
          description
        end

        def occurrences
          other_sexps.count
        end
      end
    end
  end
end
