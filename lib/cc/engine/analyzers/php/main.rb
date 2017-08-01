# frozen_string_literal: true

require "flay"
require "json"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Php
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "php"
          REQUEST_PATH = "/php".freeze
          PATTERNS = [
            "**/*.php",
          ].freeze
          DEFAULT_MASS_THRESHOLD = 28
          POINTS_PER_OVERAGE = 100_000
        end
      end
    end
  end
end
