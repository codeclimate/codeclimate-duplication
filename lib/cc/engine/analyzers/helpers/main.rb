require 'pathname'

module CC
  module Engine
    module Analyzers
      module Helpers
        BASE_POINTS = 10_000

        def parsed_hashes
          @parsed_hashes ||= []
        end

        def flay
          @flay ||= ::Flay.new(flay_options)
        end

        def report
          flay.report(StringIO.new).each do |issue|
            location = issue.locations.first
            io.puts "#{new_violation(issue, location).to_json}\0"
          end
        end

        def new_violation(issue, location)
          {
            "type": "issue",
            "check_name": name(issue),
            "description": "Duplication found in #{issue.name}",
            "categories": ["Duplication"],
            "location": format_location(issue, location),
            "remediation_points": calculate_points(issue),
            "other_locations": format_locations(issue, location),
            "content": content_body
          }
        end

        def name(issue)
          issue.identical? ? 'Identical code' : 'Similar code'
        end

        def calculate_points(issue)
          BASE_POINTS * issue.mass
        end

        def find_other_locations(all_locations, current)
          all_locations.reject { |location| location == current }
        end

        def format_location(issue, location)
          current_sexp = flay.hashes[issue.structural_hash].detect do |sexp|
            sexp.line == location.line
          end

          format_sexp(current_sexp)
        end

        def format_locations(issue, location)
          sexps = flay.hashes[issue.structural_hash].reject do |sexp|
            sexp.line == location.line
          end

          sexps.map do |sexp|
            format_sexp(sexp)
          end
        end

        def format_sexp(sexp)
          {
            "path": local_path(sexp.file),
            "lines": {
              "begin": sexp.line,
              "end": sexp_max_line(sexp, sexp.line)
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

        def flay_options
          {
            diff: false,
            mass: mass_threshold,
            summary: false,
            verbose: false,
            number: true,
            timeout: 10,
            liberal: false,
            fuzzy: false,
            only: nil
          }
        end

        def local_path(file)
          file.gsub(%r{^#{directory_path}/}, "")
        end

        def directory_path
          @directory_path ||= Pathname.new(@directory).to_s
        end

        def excluded_files
          return [] if engine_config["exclude_paths"].nil?
          engine_config["exclude_paths"].map { |path| Dir.glob("#{directory}/path") }.flatten
        end

        def content_body
          read_up = File.read('config/contents/duplicated_code.md')
          { "body": read_up }
        end
      end
    end
  end
end
