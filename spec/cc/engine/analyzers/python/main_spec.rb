require 'spec_helper'
require 'cc/engine/analyzers/python/main'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'

RSpec.describe CC::Engine::Analyzers::Python::Main, in_tmpdir: true do
  include AnalyzerSpecHelpers

  describe "#run" do
    it "prints an issue for identical code" do
      create_source_file("foo.py", <<-EOJS)
print("Hello", "python")
print("Hello", "python")
print("Hello", "python")
      EOJS

      issues = run_engine(engine_conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Identical code")
      expect(json["description"]).to eq("Identical blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(400_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.py", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 7/)
      expect(json["fingerprint"]).to eq("e5131900f15545ab1e6db6c9164926e4")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
    end

    it "prints an issue for similar code" do
      create_source_file("foo.py", <<-EOJS)
print("Hello", "python")
print("Hello It's me", "python")
print("Hello from the other side", "python")
      EOJS

      issues = run_engine(engine_conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Similar code")
      expect(json["description"]).to eq("Similar blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(400_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.py", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 7/)
      expect(json["fingerprint"]).to eq("66b17daf8d9e9bc481f734b59d5de25e")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
    end

    it "skips unparsable files" do
      create_source_file("foo.py", <<-EOPY)
        ---
      EOPY

      expect {
        expect(run_engine(engine_conf)).to eq("")
      }.to output(/Skipping file/).to_stderr
    end
  end

  it "handles an empty yml key in config" do
      create_source_file("foo.py", <<-EOPY)
def a(thing):
  print("Hello", thing)
      EOPY

      conf = CC::Engine::Analyzers::EngineConfig.new({
      "config" => {
        "languages" => {
          "python" => "",
        },
      },
    })

    expect(run_engine(engine_conf)).to eq("")
  end

  def engine_conf
    CC::Engine::Analyzers::EngineConfig.new({
      "config" => {
        "languages" => {
          "python" => {
            "mass_threshold" => 5,
          },
        },
      },
    })
  end
end
