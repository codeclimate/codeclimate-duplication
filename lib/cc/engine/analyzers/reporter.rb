require 'cc/engine/analyzers/violation'

module CC
  module Engine
    module Analyzers
      class Reporter
        TIMEOUT = 10
        def initialize(directory, language_strategy, io)
          @directory = directory
          @language_strategy = language_strategy
          @io = io
        end

        def run
          sexps = language_strategy.run

          sexps.each do |sexp|
            process_sexp(sexp)
          end

          report
        end

        def report
          flay.report(StringIO.new).each do |issue|
            io.puts "#{new_violation(issue).to_json}\0"
          end
        end

        def process_sexp(sexp)
          return unless sexp
          flay.process_sexp(sexp)
        end

        private

        def flay
          @flay ||= Flay.new(flay_options)
        end

        attr_reader :language_strategy, :directory, :io

        def mass_threshold
          @mass_threshold ||= language_strategy.mass_threshold
        end

        def new_violation(issue)
          hashes = flay.hashes[issue.structural_hash]
          Violation.new(issue, hashes, directory).format
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
