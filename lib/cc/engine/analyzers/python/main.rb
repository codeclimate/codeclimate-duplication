# frozen_string_literal: true

require "flay"
require "json"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Python
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "python"
          REQUEST_PATH = "/python/2".freeze
          PATTERNS = ["**/*.py"].freeze
          DEFAULT_MASS_THRESHOLD = 32
          POINTS_PER_OVERAGE = 50_000
        end
      end
    end
  end
end
