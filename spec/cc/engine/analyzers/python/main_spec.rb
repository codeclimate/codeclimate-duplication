require 'spec_helper'
require 'cc/engine/analyzers/python/main'
require 'cc/engine/analyzers/engine_config'

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
      expect(json["check_name"]).to eq("identical-code")
      expect(json["description"]).to eq("Identical blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(350_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.py", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 6/)
      expect(json["fingerprint"]).to eq("3f3d34361bcaef98839d9da6ca9fcee4")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MINOR)
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
      expect(json["check_name"]).to eq("similar-code")
      expect(json["description"]).to eq("Similar blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(350_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.py", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 6/)
      expect(json["fingerprint"]).to eq("019118ceed60bf40b35aad581aae1b02")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MINOR)
    end

    it "finds duplication in python3 code" do
      create_source_file("foo.py", <<-EOJS)
def a(thing: str):
  print("Hello", str)

def b(thing: str):
  print("Hello", str)

def c(thing: str):
  print("Hello", str)

def b(thing: str):
  bytes_literal = b'asdf'
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
      expect(json["check_name"]).to eq("similar-code")
      expect(json["description"]).to eq("Similar blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.py",
        "lines" => { "begin" => 1, "end" => 2 },
      })
      expect(json["remediation_points"]).to eq(900_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.py", "lines" => { "begin" => 4, "end" => 5 } },
        {"path" => "foo.py", "lines" => { "begin" => 7, "end" => 8 } },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 16/)
      expect(json["fingerprint"]).to eq("607cf2d16d829e667c5f34534197d14c")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
    end

    it "finds duplication with complex-number literals" do
      create_source_file("complex.py", <<-EOJS)
def a():
  return 1+1j

def b():
  return 1 + 1J

def c():
  return (1 + 1j)

def d():
  return 1
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
      expect(json["check_name"]).to eq("similar-code")
      expect(json["description"]).to eq("Similar blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "complex.py",
        "lines" => { "begin" => 1, "end" => 2 },
      })
      expect(json["remediation_points"]).to eq(750_000)
      expect(json["other_locations"]).to eq([
        {"path" => "complex.py", "lines" => { "begin" => 4, "end" => 5 } },
        {"path" => "complex.py", "lines" => { "begin" => 7, "end" => 8 } },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 13/)
      expect(json["fingerprint"]).to eq("f867cd91cfb73d925510a79a58619d1a")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
    end

    it "skips unparsable files" do
      create_source_file("foo.py", <<-EOPY)
        ---
      EOPY

      expect(CC.logger).to receive(:info).with(/Skipping file/)
      expect(run_engine(engine_conf)).to eq("")
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
