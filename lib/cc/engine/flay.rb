require 'flay'
require 'json'

module CC
  module Engine
    class Flay
      def initialize(directory:, engine_config:, io:)
        @directory = directory
        @engine_config = engine_config || {}
        @io = io
      end

      def run
        files = filter_files(::Flay.expand_dirs_to_files(directory))
        flay.process(*files)

        flay.report(StringIO.new).each do |issue|
          issue.locations.each { |location| puts "#{new_violation(issue, location).to_json}\0" }
        end
      end

      private

      attr_reader :directory, :engine_config, :io

      def flay
        @flay ||= ::Flay.new(options)
      end

      def new_violation(issue, location)
        {
          "type": "issue",
          "check_name": name(issue),
          "description": "Duplication found in #{issue.name}",
          "categories": ["Duplication"],
          "location": format_location(location)
        }
      end

      def name(issue)
        issue.identical? ? 'Identical code' : 'Similar code'
      end

      def filter_files(files)
        return files if engine_config["exclude_paths"].nil?
        files.reject { |file| engine_config["exclude_paths"].include?(file) }
      end

      def format_location(location)
        {
          "path": location.file,
          "lines": {
            "begin": location.line,
            "end": location.line
          }
        }
      end

      def options
        {
          diff: false,
          mass: dup_size,
          summary: false,
          verbose: false,
          number: true,
          timeout: 10,
          liberal: false,
          fuzzy: false,
          only: nil
        }
      end

      def dup_size
        engine_config[:duplication_warning_size] || 16
      end
    end
  end
end
