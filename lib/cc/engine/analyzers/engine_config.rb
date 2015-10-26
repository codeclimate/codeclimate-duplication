module CC
  module Engine
    module Analyzers
      class EngineConfig
        def initialize(hash)
          @config = normalize(hash)
        end

        def exclude_paths
          config.fetch("exclude_paths", [])
        end

        def languages
          config.fetch("languages", {})
        end

        def mass_threshold_for(language)
          fetch_language(language).fetch("mass_threshold", nil)
        end

        def paths_for(language)
          selected_language = fetch_language(language)

          if selected_language.is_a? Hash
            selected_language.fetch("paths", nil)
          end
        end

        private

        attr_reader :config

        def fetch_language(language)
          config.
            fetch("languages", {}).
            fetch(language, {})
        end

        def normalize(hash)
          hash.tap do |config|
            languages = config.fetch("config", {}).fetch("languages", {})
            config["languages"] = build_language_config(languages)
          end
        end

        def build_language_config(languages)
          if languages.is_a?(Array)
            languages.each_with_object({}) do |language, map|
              map[language.downcase] = {}
            end
          elsif languages.is_a?(Hash)
            languages.each_with_object({}) do |(key, value), map|
              map[key.downcase] = value
            end
          else
            {}
          end
        end
      end
    end
  end
end
