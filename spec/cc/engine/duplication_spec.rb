require "spec_helper"
require "cc/engine/duplication"

RSpec.describe(CC::Engine::Duplication) do
  include AnalyzerSpecHelpers

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

    it "emits parse metrics for HTTP parsed languages", in_tmpdir: true do
      create_source_file("foo.js", <<-EOJS)
        console.log("hello JS!");
      EOJS

      stdout = StringIO.new

      CC::Engine::Duplication.new(
        directory: @code, engine_config: {}, io: stdout,
      ).run

      expect(stdout.string).not_to be_empty
      measurement = JSON.parse(stdout.string.strip)
      expect(measurement).to eq(
        "name" => "javascript.parse.succeeded",
        "type" => "measurement",
        "value" => 1,
      )
    end
  end
end
