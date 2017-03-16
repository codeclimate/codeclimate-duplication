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
      expect(json["description"]).to eq("Identical code found in 2 other locations (mass = 5)")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(1_550_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.py", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 5/)
      expect(json["fingerprint"]).to eq("61363de458808105c055b631042406fd")
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
      expect(json["description"]).to eq("Similar code found in 2 other locations (mass = 5)")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(1_550_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.py", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 5/)
      expect(json["fingerprint"]).to eq("8941b71bb75571fca80cca37a3d23dc1")
    end

    it "finds duplication in python3 code" do
      create_source_file("foo.py", <<-EOJS)
def a(thing: str):
  print("Hello", str)

def b(thing: str):
  print("Hello", str)

def c(thing: str):
  print("Hello", str)
      EOJS

      conf = CC::Engine::Analyzers::EngineConfig.new({
      "config" => {
        "languages" => {
          "python" => {
            "mass_threshold" => 4,
            "python_version" => 3,
          },
        },
      },
    })
      issues = run_engine(conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Similar code")
      expect(json["description"]).to eq("Similar code found in 2 other locations (mass = 10)")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 2 },
      })
      expect(json["remediation_points"]).to eq(1_800_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 4, "end" => 5 } },
        {"path" => "foo.py", "lines" => { "begin" => 7, "end" => 8 } },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 10/)
      expect(json["fingerprint"]).to eq("eecf82b328fd464387e41b1083cdcfe6")
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
            "mass_threshold" => 4,
          },
        },
      },
    })
  end
end
