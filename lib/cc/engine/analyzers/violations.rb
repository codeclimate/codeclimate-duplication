# frozen_string_literal: true

require "cc/engine/analyzers/violation"

module CC
  module Engine
    module Analyzers
      class Violations
        def initialize(language_strategy, issue, hashes)
          @language_strategy = language_strategy
          @issue = issue
          @hashes = hashes
        end

        def each
          hashes.each_with_index do |sexp, i|
            yield Violation.new(
              current_sexp: sexp,
              other_sexps: other_sexps(hashes.dup, i),
              identical: identical?,
              language_strategy: language_strategy,
            )
          end
        end

        private

        attr_reader :language_strategy, :issue, :hashes

        def other_sexps(members, i)
          members.delete_at(i)
          members.sort_by(&:file)
        end

        def identical?
          issue.identical?
        end
      end
    end
  end
end
