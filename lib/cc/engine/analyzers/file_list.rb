module CC
  module Engine
    module Analyzers
      class FileList
        def initialize(directory:, engine_config:, extension:)
          @directory = directory
          @engine_config = engine_config
          @extension = extension
        end

        def files
          matching_files = Dir.glob("#{directory}/**/*.#{extension}").reject do |f|
            File.directory?(f)
          end

          matching_files - excluded_files
        end

        private

        attr_reader :directory, :engine_config, :extension

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
