# frozen_string_literal: true

require "cc/engine/analyzers/violations"
require "cc/engine/analyzers/file_thread_pool"
require "thread"
require "concurrent"
require "ccflay"

module CC
  module Engine
    module Analyzers
      class Reporter
        def initialize(engine_config, language_strategy, io)
          @engine_config = engine_config
          @language_strategy = language_strategy
          @io = io
          @reports = Set.new
        end

        def run
          debug("Processing #{language_strategy.files.count} #{lang} files concurrency=#{engine_config.concurrency}")

          process_files

          return dump_ast if engine_config.dump_ast?

          report

          debug("Reported #{reports.size} violations...")
        end

        def dump_ast
          require "pp"

          issues = flay.analyze

          return if issues.empty?

          debug "Sexps for issues:"
          debug

          issues.each_with_index do |issue, idx1|
            debug "#%2d) %s#%d mass=%d:" % [idx1+1,
                                          issue.name,
                                          issue.structural_hash,
                                          issue.mass]
            debug

            locs = issue.locations.map.with_index { |loc, idx2|
              "# %d.%d) %s:%s" % [idx1+1, idx2+1, loc.file, loc.line]
            }

            locs.zip(flay.hashes[issue.structural_hash]).each do |loc, sexp|
              debug loc
              debug
              debug sexp.pretty_inspect
              debug
            end

            debug
          end
        end

        def process_files
          pool = FileThreadPool.new(
            language_strategy.files,
            concurrency: engine_config.concurrency,
          )

          processed_files_count = Concurrent::AtomicFixnum.new

          pool.run do |file|
            debug("Processing #{lang} file: #{file}")

            sexp = language_strategy.run(file)

            process_sexp(sexp)

            processed_files_count.increment
          end

          pool.join

          debug("Processed #{processed_files_count.value} #{lang} files")
        end

        def lang
          CC::Engine::Duplication::LANGUAGES.invert[language_strategy.class]
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
          flay.process_sexp(language_strategy.transform_sexp(sexp))
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
          changes = {
            mass: language_strategy.mass_threshold,
            filters: language_strategy.filters,
          }

          CCFlay.default_options.merge changes
        end

        require "thread"
        IO_M = Mutex.new

        def debug(message="")
          IO_M.synchronize {
            $stderr.puts(message) if engine_config.debug?
          }
        end
      end
    end
  end
end
