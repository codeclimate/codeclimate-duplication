require 'cc/engine/analyzers/php/parser'
require 'cc/engine/analyzers/helpers/main'
require 'flay'
require 'json'

module CC
  module Engine
    module Analyzers
      module Php
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
              parser = php_parser.new(code, file).parse
              syntax_tree = parser.syntax_tree
              next if syntax_tree.nil?
              start_flay(syntax_tree.to_sexp)
            end
          end

          private

          def php_parser
            ::CC::Engine::Analyzers::Php::Parser
          end

          def mass_threshold
            engine_config.fetch('config', {}).fetch('php', {}).fetch('mass_threshold', 10)
          end

          def start_flay(s_expressions)
            flay = ::Flay.new(flay_options)
            flay.process_sexp(s_expressions)
            flay.report(StringIO.new).each do |issue|
              all_locations = issue.locations
              all_locations.each do |location|
                other_locations = find_other_locations(all_locations, location)
                io.puts "#{new_violation(issue, location, other_locations).to_json}\0"
              end
            end
          end

          def analyzed_files
            Dir.glob("#{directory}/**/*.php").reject{ |f| File.directory?(f) } - excluded_files
          end
        end
      end
    end
  end
end
