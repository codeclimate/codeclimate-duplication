module CC
  module Engine
    module Analyzers
      class EngineConfig
        def initialize(hash)
          @config = normalize(hash)
        end

        def debug?
          config.fetch("config", {}).fetch("debug", false)
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

        def mass_threshold_for(language)
          threshold = fetch_language(language).fetch("mass_threshold", nil)

          if threshold
            threshold.to_i
          end
        end

        def count_threshold_for(language)
          threshold = fetch_language(language).fetch("count_threshold", nil)
          threshold = config.fetch("count_threshold", nil) unless threshold

          if threshold
            threshold.to_i
          end
        end

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

        private

        attr_reader :config

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
