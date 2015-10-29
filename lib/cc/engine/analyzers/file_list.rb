require "pathname"

module CC
  module Engine
    module Analyzers
      class FileList
        def initialize(engine_config:, default_paths:, language:)
          @engine_config = engine_config
          @default_paths = default_paths
          @language = language
        end

        def files
          Array(matching_files) & Array(included_files)
        end

        private

        attr_reader :engine_config, :default_paths, :language

        def matching_files
          paths.map do |glob|
            Dir.glob("./#{glob}").reject do |path|
              File.directory?(path)
            end
          end.flatten
        end

        def paths
          engine_paths || default_paths
        end

        def engine_paths
          @engine_config.paths_for(language)
        end

        def included_files
          include_paths.
            map { |path| make_relative(path) }.
            map { |path| collect_files(path) }.flatten.compact
        end

        def collect_files(path)
          if File.directory?(path)
            Dir.entries(path).map do |new_path|
              next if [".", ".."].include?(new_path)
              collect_files File.join(path, new_path)
            end
          else
            path
          end
        end

        def make_relative(path)
          if path.match(%r(^\./))
            path
          else
            "./#{path}"
          end
        end

        def include_paths
          engine_config.include_paths
        end
      end
    end
  end
end
