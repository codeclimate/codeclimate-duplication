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
          matching_files - excluded_files
        end

        private

        attr_reader :engine_config, :default_paths, :language

        def matching_files
          paths.map do |glob|
            Dir.glob("./#{glob}").reject do |f|
              File.directory?(f)
            end
          end.flatten
        end

        def paths
          engine_paths || default_paths
        end

        def engine_paths
          @engine_config.paths_for(language)
        end

        def excluded_files
          @_excluded_files ||= excluded_paths.map { |path| Dir.glob("./#{path}") }.flatten
        end

        def excluded_paths
          engine_config.exclude_paths
        end
      end
    end
  end
end
