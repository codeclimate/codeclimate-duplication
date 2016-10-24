module CC
  module Engine
    module Analyzers
      module Javascript
        class MinificationChecker
          MINIFIED_AVG_LINE_LENGTH_CUTOFF = 100

          def initialize(path)
            @content = File.read(path)
          end

          def minified?
            if content.lines.count.nonzero?
              ratio = content.chars.count / content.lines.count
              ratio >= MINIFIED_AVG_LINE_LENGTH_CUTOFF
            else
              false
            end
          end

          private

          attr_reader :content
        end
      end
    end
  end
end
