module CC
  module Engine
    module Analyzers
      class FileList
        def initialize(directory:, engine_config:, default_paths:, language:)
          @directory = directory
          @engine_config = engine_config
          @default_paths = default_paths
          @language = language
        end

        def files
          matching_files - excluded_files
        end

        private

        attr_reader :directory, :engine_config, :default_paths, :language

        def matching_files
          paths.map do |glob|
            Dir.glob("#{directory}/#{glob}").reject do |f|
              File.directory?(f)
            end
          end.flatten
        end

        def paths
          engine_paths || default_paths
        end

        def engine_paths
          if current_language.is_a?(Hash)
            current_language["paths"]
          end
        end

        def current_language
          if engine_languages.is_a?(Hash)
            @current_language ||= engine_languages.fetch(language, {})
          end
        end

        def engine_languages
          @engine_language ||= engine_config.
            fetch("config", {}).
            fetch("languages", {})
        end

        def excluded_files
          excluded_paths.map { |path| Dir.glob("#{directory}/path") }.flatten
        end

        def excluded_paths
          Array(engine_config["exclude_paths"])
        end
      end
    end
  end
end
