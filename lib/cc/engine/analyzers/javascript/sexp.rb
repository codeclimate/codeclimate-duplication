require 'sexp_processor'

module CC
  module Engine
    module Analyzers
      module Javascript
        class Sexp < ::Sexp
          def structure
            result = self.class.new

            if Array === self.first then
              result = self.first.structure
            else
              result << self.first
              self[1..-1].each do |subexp|
                if subexp.is_a?(Sexp)
                  result << subexp.structure
                elsif subexp.respond_to?(:each)
                  arr = []
                  subexp.each do |s|
                    if s.is_a?(Sexp)
                      arr << s.structure
                    end
                  end
                  result << arr
                end
              end
            end

            result
          end
        end
      end
    end
  end
end
