require 'flay'
require 'json'
require 'cc/engine/analyzers/helpers/main'

module CC
  module Engine
    module Analyzers
      module Ruby
        class Main
          include ::CC::Engine::Analyzers::Helpers

          def initialize(directory:, engine_config:, io:)
            @directory = directory
            @engine_config = engine_config || {}
            @io = io
          end

          def run
            flay.process(*analyzed_files)

            flay.report(StringIO.new).each do |issue|
              all_locations = issue.locations

              all_locations.each do |location|
                other_locations = find_other_locations(all_locations, location)
                io.puts "#{new_violation(issue, location, other_locations).to_json}\0"
              end
            end
          end

          private

          attr_reader :directory, :engine_config, :io

          def filter_files(files)
            return files if engine_config["exclude_paths"].nil?
            files - excluded_files
          end

          def mass_threshold
            mass = engine_config.fetch('config', {}).fetch('ruby', {}).fetch('mass_threshold', {})
            mass.empty? ? 10 : mass
          end

          def analyzed_files
            filter_files(::Flay.expand_dirs_to_files(directory))
          end
        end
      end
    end
  end
end

