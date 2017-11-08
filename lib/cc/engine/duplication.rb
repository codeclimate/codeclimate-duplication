# frozen_string_literal: true

require "bundler/setup"
require "cc/engine/analyzers/ruby/main"
require "cc/engine/analyzers/java/main"
require "cc/engine/analyzers/javascript/main"
require "cc/engine/analyzers/php/main"
require "cc/engine/analyzers/python/main"
require "cc/engine/analyzers/reporter"
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
        "php"        => ::CC::Engine::Analyzers::Php::Main,
        "python"     => ::CC::Engine::Analyzers::Python::Main,
        "typescript" => ::CC::Engine::Analyzers::TypeScript::Main,
      }.freeze

      def initialize(directory:, engine_config:, io:)
        @directory = directory
        @engine_config = CC::Engine::Analyzers::EngineConfig.new(engine_config || {})
        @io = io
      end

      def run
        Dir.chdir(directory) do
          languages_to_analyze.each do |language|
            engine = LANGUAGES[language].new(engine_config: engine_config)
            reporter = CC::Engine::Analyzers::Reporter.new(engine_config, engine, io)
            reporter.run
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
