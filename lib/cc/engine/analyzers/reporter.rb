require 'cc/engine/analyzers/violation'
require 'cc/engine/analyzers/file_thread_pool'
require 'thread'

module CC
  module Engine
    module Analyzers
      class Reporter
        TIMEOUT = 10

        def initialize(engine_config, language_strategy, io)
          @engine_config = engine_config
          @language_strategy = language_strategy
          @io = io
          @reports = Set.new
        end

        def run
          process_files
          report
        end

        def process_files
          pool = FileThreadPool.new(
            language_strategy.files,
            concurrency: engine_config.concurrency
          )

          pool.run do |file|
            sexp = language_strategy.run(file)
            process_sexp(sexp)
          end

          pool.join
        end

        def report
          flay.report(StringIO.new).each do |issue|
            next unless issue_above_threshold?(issue)
            violation = new_violation(issue)

            unless reports.include?(violation.report_name)
              reports.add(violation.report_name)
              io.puts "#{violation.format.to_json}\0"
            end
          end
        end

        def process_sexp(sexp)
          return unless sexp
          flay.process_sexp(sexp)
        end

        private

        attr_reader :reports

        def flay
          @flay ||= Flay.new(flay_options)
        end

        attr_reader :engine_config, :language_strategy, :io

        def mass_threshold
          @mass_threshold ||= [
            language_strategy.mass_threshold_for_check(:identical),
            language_strategy.mass_threshold_for_check(:similar),
          ].min
        end

        def issue_above_threshold?(issue)
          base_mass = issue.mass / issue.locations.count
          if issue.identical?
            base_mass >= language_strategy.mass_threshold_for_check(:identical)
          else
            base_mass >= language_strategy.mass_threshold_for_check(:similar)
          end
        end

        def new_violation(issue)
          hashes = flay.hashes[issue.structural_hash]
          Violation.new(language_strategy.base_points, issue, hashes)
        end

        def flay_options
          {
            diff: false,
            mass: mass_threshold,
            summary: false,
            verbose: false,
            number: true,
            timeout: TIMEOUT,
            liberal: false,
            fuzzy: false,
            only: nil
          }
        end
      end
    end
  end
end
