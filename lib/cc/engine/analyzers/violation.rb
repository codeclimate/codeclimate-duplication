module CC
  module Engine
    module Analyzers
      class Violation
        attr_reader :issue

        def initialize(base_points, issue, hashes, directory)
          @base_points = base_points
          @issue = issue
          @hashes = hashes
          @directory = directory
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
            "content": content_body
          }
        end

        private

        attr_reader :base_points, :hashes, :directory

        def current_sexp
          @location ||= hashes.first
        end

        def other_sexps
          @other_locations ||= hashes.drop(1)
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
          relative_path = sexp.file.gsub(/^#{directory}\//, "")
          {
            "path": relative_path,
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
          read_up = File.read('config/contents/duplicated_code.md')
          { "body": read_up }
        end

        def description
          description = "*Similar code* found in #{occurrences} other location"
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
