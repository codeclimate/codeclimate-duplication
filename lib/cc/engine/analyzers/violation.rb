require "cc/engine/analyzers/issue"

module CC
  module Engine
    module Analyzers
      class Violation
        def initialize(language_strategy, issue, hashes)
          @language_strategy = language_strategy
          @hashes = hashes
          @issue = issue
        end

        def occurrences
          hashes.map.with_index do |sexp, i|
            Issue.new(language_strategy: language_strategy, check_name: check_name, current_sexp: sexp, other_sexps: other_sexps(hashes.dup, i))
          end
        end

        private

        attr_reader :language_strategy, :hashes, :issue

        def check_name
          if issue.identical?
            "Identical code"
          else
            "Similar code"
          end
        end

        def other_sexps(members, i)
          members.delete_at(i)
          members.sort_by(&:file)
        end
      end
    end
  end
end
