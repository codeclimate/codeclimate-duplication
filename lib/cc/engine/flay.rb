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
          puts "#{new_violation(issue).to_json}\0"
        end
      end

      private

      attr_reader :directory, :engine_config, :io

      def flay
        @flay ||= ::Flay.new
      end

      def new_violation(issue)
        {
          "type": "issue",
          "check_name": name(issue),
          "description": "Duplication found in #{issue.name}",
          "categories": ["Duplication"],
          "location": locations(issue)
        }
      end

      def name(issue)
        issue.identical? ? 'Identical code' : 'Similar code'
      end

      def filter_files(files)
        return files if engine_config["exclude_paths"].nil?
        files.reject { |file| engine_config["exclude_paths"].include?(file) }
      end

      def locations(issue)
        issue.locations.map do |loc|
          {
            "path": loc.file,
            "lines": {
              "begin": loc.line,
              "end": loc.line
            }
          }
        end
      end
    end
  end
end
