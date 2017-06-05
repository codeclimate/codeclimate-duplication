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
        IO_M = Mutex.new

        def initialize(engine_config, language_strategy, io)
          @engine_config = engine_config
          @language_strategy = language_strategy
          @io = io
          @reports = Set.new
        end

        def run
          CC.logger.debug("Processing #{language_strategy.files.count} #{lang} files concurrency=#{engine_config.concurrency}")

          process_files

          if engine_config.dump_ast?
            dump_ast
          else
            report
            CC.logger.debug("Reported #{reports.size} violations...")
          end
        end

        def dump_ast
          require "pp"

          issues = flay.analyze

          return if issues.empty?

          CC.logger.debug("Sexps for issues:")

          issues.each_with_index do |issue, idx1|
            CC.logger.debug(
              format(
                "#%2d) %s#%d mass=%d:",
                idx1 + 1,
                issue.name,
                issue.structural_hash,
                issue.mass,
              ),
            )

            locs = issue.locations.map.with_index do |loc, idx2|
              format("# %d.%d) %s:%s", idx1 + 1, idx2 + 1, loc.file, loc.line)
            end

            locs.zip(flay.hashes[issue.structural_hash]).each do |loc, sexp|
              CC.logger.debug(loc)
              CC.logger.debug(sexp.pretty_inspect)
            end
          end
        end

        def process_files
          pool = FileThreadPool.new(
            language_strategy.files,
            concurrency: engine_config.concurrency,
          )

          processed_files_count = Concurrent::AtomicFixnum.new

          pool.run do |file|
            CC.logger.debug("Processing #{lang} file: #{file}")

            sexp = language_strategy.run(file)

            process_sexp(sexp)

            processed_files_count.increment
          end

          pool.join

          CC.logger.debug("Processed #{processed_files_count.value} #{lang} files")
        end

        def lang
          CC::Engine::Duplication::LANGUAGES.invert[language_strategy.class]
        end

        def report
          flay.analyze.each do |issue|
            violations = new_violations(issue)

            violations.each do |violation|
              next if skip?(violation)
              CC.logger.debug("Violation name=#{violation.report_name} mass=#{violation.mass}")

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

        def skip?(violation)
          insufficient_occurrence?(violation) || check_disabled?(violation)
        end

        def insufficient_occurrence?(violation)
          (violation.occurrences + 1) < language_strategy.count_threshold
        end

        def check_disabled?(violation)
          if violation.identical?
            !engine_config.identical_code_check_enabled?
          else
            !engine_config.similar_code_check_enabled?
          end
        end
      end
    end
  end
end
