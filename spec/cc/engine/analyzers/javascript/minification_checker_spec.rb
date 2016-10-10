require "spec_helper"
require "cc/engine/analyzers/javascript/minification_checker"

module CC
  module Engine
    module Analyzers
      module Javascript
        RSpec.describe MinificationChecker do
          include AnalyzerSpecHelpers

          describe "minified?" do
            it "returns true for a minified file" do
              path = fixture_path("huge_js_file.js")
              expect(MinificationChecker.new(path)).to be_minified
            end

            it "returns false for non-minified files" do
              path = fixture_path("normal_js_file.js")
              expect(MinificationChecker.new(path)).to_not be_minified
            end
          end
        end
      end
    end
  end
end
