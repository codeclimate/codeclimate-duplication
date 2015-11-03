require 'cc/engine/analyzers/ruby/main'
require 'cc/engine/analyzers/javascript/main'
require 'cc/engine/analyzers/php/main'
require 'cc/engine/analyzers/python/main'
require 'cc/engine/analyzers/reporter'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/sexp'
require 'flay'
require 'json'

module CC
  module Engine
    class Duplication
      EmptyLanguagesError = Class.new(StandardError)

      LANGUAGES = {
        "ruby"       => ::CC::Engine::Analyzers::Ruby::Main,
        "javascript" => ::CC::Engine::Analyzers::Javascript::Main,
        "php"        => ::CC::Engine::Analyzers::Php::Main,
        "python"     => ::CC::Engine::Analyzers::Python::Main,
      }.freeze

      def initialize(directory:, engine_config:, io:)
        Dir.chdir(directory)
        @engine_config = CC::Engine::Analyzers::EngineConfig.new(engine_config || {})
        @io = io
      end

      def run
        languages_to_analyze.each do |language|
          engine = LANGUAGES[language].new(engine_config: engine_config)
          reporter = CC::Engine::Analyzers::Reporter.new(engine_config, engine, io)
          reporter.run
        end
      end

      private

      attr_reader :engine_config, :io

      def languages_to_analyze
        languages.select do |language|
          LANGUAGES.keys.include?(language)
        end
      end

      def languages
        languages = engine_config.languages.keys

        if languages.empty?
          message = "Config Error: Unable to run the duplication engine without any languages enabled."
          $stderr.puts message
          raise EmptyLanguagesError, message
        else
          languages
        end
      end
    end
  end
end
