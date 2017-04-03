# frozen_string_literal: true

module CC
  module Engine
    module Analyzers
      class ParserBase
        private

        def parse_json(text)
          JSON.parse(text, max_nesting: false)
        end
      end
    end
  end
end
