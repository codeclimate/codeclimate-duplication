require 'pathname'

module CC
  module Engine
    module Analyzers
      module Helpers
        BASE_POINTS = 10_000

        def flay
          @flay ||= ::Flay.new(options)
        end

        def new_violation(issue, location, other)
          {
            "type": "issue",
            "check_name": name(issue),
            "description": "Duplication found in #{issue.name}",
            "categories": ["Duplication"],
            "location": format_location(location),
            "remediation_points": calculate_points(issue),
            "other_locations": format_locations(other),
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

        def format_location(location)
          {
            "path": local_path(location.file),
            "lines": {
              "begin": location.line,
              "end": location.line
            }
          }
        end

        def format_locations(other)
          other.map { |location| format_location(location) }
        end

        def options
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
          @directory_path ||= Pathname.new(@directory).realpath.to_s
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
