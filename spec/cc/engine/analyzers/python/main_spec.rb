require "spec_helper"
require "cc/engine/analyzers/python/main"
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'
require "flay"
require "tmpdir"

RSpec.describe CC::Engine::Analyzers::Python::Main, in_tmpdir: true do
  include AnalyzerSpecHelpers

  describe "#run" do
    it "prints an issue" do

      create_source_file("foo.py", <<-EOJS)
print("Hello", "python")
print("Hello", "python")
print("Hello", "python")
      EOJS

      result = run_engine(engine_conf).strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Identical code")
      expect(json["description"]).to eq("Similar code found in 2 other locations")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(54000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.py", "lines" => { "begin" => 3, "end" => 3} }
      ])
      expect(json["content"]["body"]).to match /This issue has a mass of `54`/
      expect(json["fingerprint"]).to eq("42b832387c997f54a2012efb2159aefc")
    end
  end

  def engine_conf
    CC::Engine::Analyzers::EngineConfig.new(engine_config_for_language({
      "mass_threshold" => 4,
    }))
  end
end
