# frozen_string_literal: true

require "cc/engine/analyzers/analyzer_base"
require "cc/engine/analyzers/reporter"

module CC
  module Engine
    module Analyzers
      module Ruby
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "ruby"
          REQUEST_PATH = "/ruby".freeze
          PATTERNS = [
            "**/*.rb",
          ].freeze
          DEFAULT_MASS_THRESHOLD = 25
          BASE_POINTS = 150_000
          POINTS_PER_OVERAGE = 20_000
          TIMEOUT = 300
        end
      end
    end
  end
end
