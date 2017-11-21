require "spec_helper"

require "cc/engine/analyzers/violation"

module CC::Engine::Analyzers
  RSpec.describe Violation do
    describe "#format" do
      it "gives the correct path for paths with leading single char dir" do
        sexp1 = Sexp.new([:foo, :a]).tap do |s|
          s.line = 42
          s.file = "_/a.rb"
        end
        sexp2 = Sexp.new([:foo, :a]).tap do |s|
          s.line = 13
          s.file = "T/b.rb"
        end
        engine_config = EngineConfig.new({})
        language_strategy = Ruby::Main.new(
          engine_config: engine_config,
          parse_metrics: nil,
        )
        issue = described_class.new(
          language_strategy: language_strategy,
          identical: true,
          current_sexp: sexp1,
          other_sexps: [sexp2],
        ).format

        expect(issue[:location][:path]).to eq("_/a.rb")
        expect(issue[:other_locations][0][:path]).to eq("T/b.rb")
      end
    end
  end
end
