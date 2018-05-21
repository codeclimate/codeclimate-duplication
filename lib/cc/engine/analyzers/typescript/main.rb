# frozen_string_literal: true

require "cc/engine/analyzers/javascript/main"

module CC
  module Engine
    module Analyzers
      module TypeScript # TODO: inconsistent naming w/ Javascript
        class Main < CC::Engine::Analyzers::Javascript::Main
          PATTERNS = [
            "**/*.ts",
            "**/*.tsx",
          ].freeze

          LANGUAGE = "typescript"

          REQUEST_PATH = "/typescript".freeze
        end
      end
    end
  end
end
