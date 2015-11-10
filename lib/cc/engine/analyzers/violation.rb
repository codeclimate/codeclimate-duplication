require "digest"

module CC
  module Engine
    module Analyzers
      class Violation
        attr_reader :issue

        def initialize(base_points, issue, hashes, reports)
          @base_points = base_points
          @issue = issue
          @hashes = hashes
          @reports = reports
        end

        def format
          {
            "type": "issue",
            "check_name": name,
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

        attr_reader :base_points, :hashes, :reports

        def current_sexp
          @location ||= sorted_hashes.first
        end

        def sorted_hashes
          @_sorted_hashes ||= hashes.sort_by(&:file)
        end

        def other_sexps
          @_other_sexps ||= hashes.drop(1).reject do |hash|
            report_name = "#{hash.file}-#{hash.line}"
            reports.include?(report_name).tap do
              reports.add(report_name)
            end
          end
        end

        def name
          if issue.identical?
            "Identical code"
          else
            "Similar code"
          end
        end

        def calculate_points
          base_points * issue.mass
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
          {
            "path": sexp.file.gsub(%r(^./), ""),
            "lines": {
              "begin": sexp.line,
              "end": sexp.end_line || sexp_max_line(sexp, sexp.line)
            }
          }
        end

        def sexp_max_line(sexp_tree, default)
          max = default

          sexp_tree.deep_each do |sexp|
            max = sexp.line if sexp.line > max
          end

          max
        end

        def content_body
          @_content_body ||= { "body": File.read(read_up_path) }
        end

        def read_up_path
          relative_path = "../../../../config/contents/duplicated_code.md"
          File.expand_path(
            File.join(File.dirname(__FILE__), relative_path)
          )
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
          description = "Similar code found in #{occurrences} other location"
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
