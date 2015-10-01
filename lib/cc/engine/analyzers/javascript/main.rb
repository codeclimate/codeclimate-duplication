require 'cc/engine/analyzers/javascript/parser'
require 'cc/engine/analyzers/helpers/main'
require 'flay'
require 'json'

module CC
  module Engine
    module Analyzers
      module Javascript
        class Main
          include ::CC::Engine::Analyzers::Helpers

          attr_reader :directory, :engine_config, :io

          def initialize(directory:, engine_config:, io:)
            @directory = directory
            @engine_config = engine_config || {}
            @io = io
          end

          def run
            analyzed_files.each do |file|
              code = File.read(file)
              parser = js_parser.new(code, file).parse
              syntax_tree = parser.syntax_tree

              next if syntax_tree.nil?
              start_flay(syntax_tree.to_sexp)
            end
          end

          private

          def js_parser
            ::CC::Engine::Analyzers::Javascript::Parser
          end

          def mass_threshold
            engine_config.fetch('config', {}).fetch('javascript', {}).fetch('mass_threshold', 10)
          end

          def start_flay(s_expressions)
            flay = ::Flay.new(flay_options)
            flay.process_sexp(s_expressions)
          end

          def analyzed_files
            Dir.glob("#{directory}/**/*.js").reject{ |f| File.directory?(f) } - excluded_files
          end
        end
      end
    end
  end
end
