# frozen_string_literal: true

module CC
  module Engine
    module Analyzers
      class EngineConfig
        DEFAULT_COUNT_THRESHOLD = 2
        IDENTICAL_CODE_CHECK = "identical-code".freeze
        SIMILAR_CODE_CHECK = "similar-code".freeze

        InvalidConfigError = Class.new(StandardError)

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
          config.fetch("config", {}).fetch("concurrency", 2).to_i
        end

        def dump_ast?
          config.fetch("config", {}).fetch("dump_ast", false)
        end

        def filters_for(language)
          fetch_language(language).fetch("filters", []).map do |filter|
            Sexp::Matcher.parse filter
          end
        end

        def identical_code_check_enabled?
          enabled?(IDENTICAL_CODE_CHECK)
        end

        def similar_code_check_enabled?
          enabled?(SIMILAR_CODE_CHECK)
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

        def patterns_for(language, fallbacks)
          Array(fetch_language(language).fetch("patterns", fallbacks))
        end

        private

        attr_reader :config

        def normalize(hash)
          hash.tap do |config|
            languages = config.fetch("config", {}).fetch("languages") do
              default_languages
            end
            config["languages"] = build_language_config(languages)
          end
        end

        def default_languages
          tuples = Duplication::LANGUAGES.map do |language, _|
            [language, {}]
          end
          Hash[tuples]
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

        def checks
          config.fetch("config", {}).fetch("checks", {})
        end

        def enabled?(check)
          checks.fetch(check, {}).fetch("enabled", true)
        end
      end
    end
  end
end
