module CC
  module Engine
    module Analyzers
      class EngineConfig
        DEFAULT_COUNT_THRESHOLD = 2
        InvalidConfigError = Class.new(StandardError)

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
          threshold = fetch_language(language)["count_threshold"] ||
            config.fetch("config", {}).fetch("count_threshold", nil) ||
            DEFAULT_COUNT_THRESHOLD

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
              language, config = coerce_array_entry(language)
              map[language.downcase] = config
            end
          elsif languages.is_a?(Hash)
            languages.each_with_object({}) do |(key, value), map|
              map[key.downcase] = value
            end
          else
            raise InvalidConfigError, "languages config entry is invalid: please check documentation for details of configuring languages"
          end
        end

        def coerce_array_entry(entry)
          if entry.is_a?(String)
            [entry.downcase, {}]
          elsif entry.is_a?(Hash) && entry.keys.count == 1
            [entry.keys.first, entry[entry.keys.first]]
          else
            raise InvalidConfigError, "#{entry.inspect} is not a valid language entry"
          end
        end
      end
    end
  end
end
