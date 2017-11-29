# frozen_string_literal: true

require "pathname"

module CC
  module Engine
    module Analyzers
      class FileList
        def initialize(engine_config:, patterns:)
          @engine_config = engine_config
          @patterns = patterns
        end

        def files
          engine_config.include_paths.flat_map do |path|
            pathname = Pathname.new(path)
            if pathname.directory? && !pathname.cleanpath.symlink?
              expand(path)
            elsif pathname.file? && !pathname.symlink? && matches?(path)
              [path]
            else
              []
            end
          end
        end

        private

        attr_reader :engine_config, :patterns

        def expand(path)
          globs = patterns.map { |p| File.join(relativize(path), p) }

          Dir.glob(globs).select { |f| File.file?(f) && !File.symlink?(f) }
        end

        def matches?(path)
          patterns.any? do |p|
            File.fnmatch?(
              relativize(p),
              relativize(path),
              File::FNM_PATHNAME | File::FNM_EXTGLOB,
            )
          end
        end

        # Ensure all paths (and patterns) are ./-prefixed
        def relativize(path)
          "./#{path.sub(%r{^\./}, "")}"
        end
      end
    end
  end
end
