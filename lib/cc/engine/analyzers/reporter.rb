require 'cc/engine/analyzers/violations'
require 'cc/engine/analyzers/file_thread_pool'
require 'thread'
require "concurrent"
require "ccflay"

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
          debug("Processing #{language_strategy.files.count} files concurrency=#{engine_config.concurrency}")

          process_files
          report

          debug("Reported #{reports.size} violations...")
        end

        def process_files
          pool = FileThreadPool.new(
            language_strategy.files,
            concurrency: engine_config.concurrency,
          )

          processed_files_count = Concurrent::AtomicFixnum.new

          pool.run do |file|
            debug("Processing file: #{file}")

            sexp = language_strategy.run(file)
            process_sexp(sexp)

            processed_files_count.increment
          end

          pool.join

          debug("Processed #{processed_files_count.value} files")
        end

        def report
          flay.analyze.each do |issue|
            violations = new_violations(issue)

            violations.each do |violation|
              next if (violation.occurrences + 1) < language_strategy.count_threshold
              debug("Violation name=#{violation.report_name} mass=#{violation.mass}")

              unless reports.include?(violation.report_name)
                reports.add(violation.report_name)
                io.puts "#{violation.format.to_json}\0"
              end
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
          @flay ||= CCFlay.new(flay_options)
        end

        attr_reader :engine_config, :language_strategy, :io

        def new_violations(issue)
          hashes = flay.hashes[issue.structural_hash]
          Violations.new(language_strategy, issue, hashes)
        end

        def flay_options
          {
            diff: false,
            mass: language_strategy.mass_threshold,
            summary: false,
            verbose: false,
            number: true,
            timeout: TIMEOUT,
            liberal: false,
            fuzzy: false,
            only: nil,
          }
        end

        def debug(message)
          $stderr.puts(message) if engine_config.debug?
        end
      end
    end
  end
end
