# frozen_string_literal: true

require "bundler/setup"
require "cc/engine/parse_metrics"
require "cc/engine/analyzers/ruby/main"
require "cc/engine/analyzers/java/main"
require "cc/engine/analyzers/kotlin/main"
require "cc/engine/analyzers/javascript/main"
require "cc/engine/analyzers/go/main"
require "cc/engine/analyzers/php/main"
require "cc/engine/analyzers/python/main"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/scala/main"
require "cc/engine/analyzers/swift/main"
require "cc/engine/analyzers/typescript/main"
require "cc/engine/analyzers/engine_config"
require "cc/engine/analyzers/sexp"
require "flay"
require "json"

module CC
  module Engine
    class Duplication
      LANGUAGES = {
        "ruby"       => ::CC::Engine::Analyzers::Ruby::Main,
        "java"       => ::CC::Engine::Analyzers::Java::Main,
        "javascript" => ::CC::Engine::Analyzers::Javascript::Main,
        "kotlin"     => ::CC::Engine::Analyzers::Kotlin::Main,
        "php"        => ::CC::Engine::Analyzers::Php::Main,
        "python"     => ::CC::Engine::Analyzers::Python::Main,
        "typescript" => ::CC::Engine::Analyzers::TypeScript::Main,
        "go"         => ::CC::Engine::Analyzers::Go::Main,
        "scala"      => ::CC::Engine::Analyzers::Scala::Main,
        "swift"      => ::CC::Engine::Analyzers::Swift::Main,
      }.freeze

      def initialize(directory:, engine_config:, io:)
        @directory = directory
        @engine_config = CC::Engine::Analyzers::EngineConfig.new(engine_config || {})
        @io = io
      end

      def run
        return if engine_config.all_checks_disabled?

        Dir.chdir(directory) do
          languages_to_analyze.each do |language|
            parse_metrics = ParseMetrics.new(
              language: language,
              io: io,
            )
            engine = LANGUAGES[language].new(
              engine_config: engine_config,
              parse_metrics: parse_metrics,
            )
            reporter = CC::Engine::Analyzers::Reporter.new(engine_config, engine, io)
            reporter.run
            parse_metrics.report
          end
        end
      end

      private

      attr_reader :directory, :engine_config, :io

      def languages_to_analyze
        engine_config.languages.keys.select do |language|
          LANGUAGES.keys.include?(language)
        end
      end
    end
  end
end
