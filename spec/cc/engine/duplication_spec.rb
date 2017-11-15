require "spec_helper"
require "cc/engine/duplication"

RSpec.describe(CC::Engine::Duplication) do
  describe "#run" do
    it "skips analysis when all duplication checks are disabled" do
      dir = "foo"
      config = {
        "config" => {
          "checks" => {
            "similar-code" => {
              "enabled" => false,
            },
            "identical-code" => {
              "enabled" => false,
            },
          },
        },
      }
      expect(Dir).to_not receive(:chdir)
      expect(CC::Engine::Analyzers::Reporter).to_not receive(:new)

      CC::Engine::Duplication.new(
        directory: dir, engine_config: config, io: double,
      ).run
    end
  end
end
