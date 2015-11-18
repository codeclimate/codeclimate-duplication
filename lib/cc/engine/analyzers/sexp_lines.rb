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
          @end_line = root_sexp.end_line || root_sexp.line

          root_sexp.deep_each do |sexp|
            @begin_line = [@begin_line, sexp.line].min
            @end_line = [@end_line, sexp.end_line || sexp.line].max
          end
        end
      end
    end
  end
end
