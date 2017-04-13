# frozen_string_literal: true

module CC
  module Engine
    module Analyzers
      class SexpLines
        attr_reader :begin_line, :end_line

        def initialize(root_sexp)
          @root_sexp = root_sexp
          calculate
        end

        private

        attr_reader :root_sexp

        def calculate
          @begin_line = root_sexp.line
          @end_line = root_sexp.end_line || root_sexp.line_max

          if @end_line < @begin_line
            @begin_line = root_sexp.line_min
          end
        end
      end
    end
  end
end

class Sexp
  # override to cache... TODO: add back to sexp_processor, then remove this
  def line_min
    @line_min ||= deep_each.map(&:line).min
  end

  # override to cache... TODO: add back to sexp_processor, then remove this
  def line_max
    @line_max ||= deep_each.map(&:line).max
  end
end
