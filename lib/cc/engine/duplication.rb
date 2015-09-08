require 'cc/engine/analyzers/ruby/main'
require 'cc/engine/analyzers/javascript/main'
require 'flay'
require 'json'
require 'pry'

module CC
  module Engine
    class Duplication
      SUPPORTED_LANGUAGES = ['ruby', 'javascript'].freeze

      def initialize(directory:, engine_config:, io:)
        @directory = directory
        @engine_config = engine_config || {}
        @io = io
      end

      def run
        return unless any_enabled_languages?

        languages.each do |lang|
          next unless language_supported?(lang)
          klass = "::CC::Engine::Analyzers::#{lang.capitalize}::Main"
          Object.const_get(klass).new(directory: directory, engine_config: engine_config, io: io).run
        end
      end

      private

      attr_reader :directory, :engine_config, :io

      def any_enabled_languages?
        !languages.empty?
      end

      def languages
        SUPPORTED_LANGUAGES
        # engine_config['languages'] || {}
      end

      def language_supported?(lang)
        SUPPORTED_LANGUAGES.include?(lang)
      end
    end
  end
end
