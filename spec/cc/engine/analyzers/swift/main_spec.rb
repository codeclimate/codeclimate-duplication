require "spec_helper"
require "cc/engine/analyzers/swift/main"
require "cc/engine/analyzers/engine_config"

RSpec.describe CC::Engine::Analyzers::Swift::Main, in_tmpdir: true do
  include AnalyzerSpecHelpers

  describe "#run" do
    it "prints an issue for identical code" do
      create_source_file("foo.swift", <<-EOSWIFT)
      if (x < 10 && false || true && false || true) {
          print("complex")
      }

      if (x < 10 && false || true && false || true) {
          print("complex")
      }

      if (x < 10 && false || true && false || true) {
          print("complex")
      }
      EOSWIFT

      issues = run_engine(engine_conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("identical-code")
      expect(json["description"]).to eq("Identical blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.swift",
        "lines" => { "begin" => 1, "end" => 3 },
      })
      expect(json["remediation_points"]).to eq(700_000)
      expect(json["other_locations"]).to eq([
        {
          "path" => "foo.swift",
          "lines" => { "begin" => 5, "end" => 7 }
        },
        {
          "path" => "foo.swift",
          "lines" => { "begin" => 9, "end" => 11 }
        },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 41/)
      expect(json.key?("fingerprint")).to eq(true)
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
    end

    it "prints an issue for similar code" do
      create_source_file("foo.swift", <<-EOSWIFT)
      if (x < 15 || false || true && false) {
          print("also complex")
      }

      if (x < 10 && false || true && false) {
          print("complex")
      }
      EOSWIFT

      issues = run_engine(engine_conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("similar-code")
      expect(json["description"]).to eq("Similar blocks of code found in 2 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.swift",
        "lines" => { "begin" => 1, "end" => 3 },
      })
      expect(json["remediation_points"]).to eq(660_000)
      expect(json["other_locations"]).to eq([
        {
          "path" => "foo.swift",
          "lines" => { "begin" => 5, "end" => 7 }
        },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 37/)
      expect(json.key?("fingerprint")).to eq(true)
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
    end

    it "skips unparsable files" do
      create_source_file("foo.swift", <<-EOTS)
        func() { // missing closing brace
      EOTS

      expect(CC.logger).to receive(:warn).with(/Skipping \.\/foo\.swift/)
      expect(CC.logger).to receive(:warn).with("Response status: 422")
      expect(run_engine(engine_conf)).to eq("")
    end

    it "does not flag duplicate comments" do
      create_source_file("foo.swift", <<-EOSWIFT)
      // A comment.
      // A comment.

      /* A comment. */
      /* A comment. */
      EOSWIFT

      expect(run_engine(engine_conf)).to be_empty
    end

    it "ignores imports" do
      create_source_file("foo.swift", <<~EOTS)
      import Foundation
      import UIKit
      EOTS

      create_source_file("bar.swift", <<~EOTS)
      import Foundation
      import UIKit
      EOTS

      issues = run_engine(engine_conf).strip.split("\0")
      expect(issues).to be_empty
    end
  end

  def engine_conf
    CC::Engine::Analyzers::EngineConfig.new({
      'config' => {
        'checks' => {
          'similar-code' => {
            'enabled' => true,
          },
          'identical-code' => {
            'enabled' => true,
          },
        },
        'languages' => {
          'swift' => {
            'mass_threshold' => 1,
          },
        },
      },
    })
  end
end
