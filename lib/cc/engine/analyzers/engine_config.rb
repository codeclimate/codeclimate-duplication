module CC
  module Engine
    module Analyzers
      class EngineConfig
        def initialize(hash)
          @config = normalize(hash)
        end

        def include_paths
          config.fetch("include_paths", ["./"])
        end

        def languages
          config.fetch("languages", {})
        end

        def concurrency
          config.fetch("concurrency", 2)
        end

        def identical_mass_threshold_for(language)
          mass_threshold_with_fallback(language, "identical_mass_threshold")
        end

        def similar_mass_threshold_for(language)
          mass_threshold_with_fallback(language, "similar_mass_threshold")
        end

        def paths_for(language)
          fetch_language(language).fetch("paths", nil)
        end

        private

        attr_reader :config

        def fetch_language(language)
          language = config.
            fetch("languages", {}).
            fetch(language, {})

          if language.is_a? Hash
            language
          else
            {}
          end
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

        def mass_threshold_with_fallback(language, key)
          language_hash = fetch_language(language)
          threshold = language_hash.fetch(key) do |key|
            language_hash.fetch("mass_threshold", nil)
          end

          threshold.to_i if threshold
        end
      end
    end
  end
end
