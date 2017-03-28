require 'spec_helper'
require 'cc/engine/analyzers/php/main'
require 'cc/engine/analyzers/reporter'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'

RSpec.describe CC::Engine::Analyzers::Php::Main, in_tmpdir: true do
  include AnalyzerSpecHelpers

  describe "#run" do
    it "prints an issue for identical code" do
      create_source_file("foo.php", <<-EOPHP)
          <?php
          function hello($name) {
            if (empty($name)) {
              echo "Hello World!";
            } else {
              echo "Hello $name!";
            }
          }

          function hi($name) {
            if (empty($name)) {
              echo "Hi World!";
            } else {
              echo "Hi $name!";
            }
          }
      EOPHP

      issues = run_engine(engine_conf).strip.split("\0")
      expect(issues.length).to be > 0
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Identical code")
      expect(json["description"]).to eq("Identical code found in 1 other location (mass = 11)")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.php",
        "lines" => { "begin" => 2, "end" => 6 },
      })
      expect(json["remediation_points"]).to eq(2_100_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.php", "lines" => { "begin" => 10, "end" => 14} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 11/)
      expect(json["fingerprint"]).to eq("8234e10d96fd6ef608085c22c91c9ab1")
    end

    it "runs against complex files" do
      FileUtils.cp(fixture_path("symfony_configuration.php"), File.join(@code, "configuration.php"))
      issues = run_engine(engine_conf).strip.split("\0")
      expect(issues.length).to be > 0
      result = issues.first.strip

      expect(result).to match "\"type\":\"issue\""
    end

    it "handles INF & NAN constants" do
      create_source_file("foo.php", <<-EOPHP)
          <?php
          function f1($name) {
            // the php-parser lib turns this into INF, but writing INF directly gets emitted differently
            if (empty($name)) {
              return 646e444;
            } else {
              return 0;
            }
          }

          function f2($name) {
            if (empty($name)) {
              return 646e444;
            } else {
              return 0;
            }
          }
      EOPHP

      result = run_engine(engine_conf).strip
      expect(result).to match "\"type\":\"issue\""
    end

    it "skips unparsable files" do
      create_source_file("foo.php", <<-EOPHP)
        <?php blorb &; "fee
      EOPHP

      expect {
        expect(run_engine(engine_conf)).to eq("")
      }.to output(/Skipping file/).to_stderr
    end

    it "can parse php 7 code" do
      create_source_file("foo.php", File.read(fixture_path("from_phan_php7.php")))
      issues = run_engine(engine_conf).strip.split("\0")
      expect(issues.length).to be > 0
      result = issues.first.strip
      json = JSON.parse(result)
      expect(json["location"]).to eq({
        "path" => "foo.php",
        "lines" => { "begin" => 117, "end" => 118 },
      })
    end

    it "can parse php 7.1 code" do
      create_source_file("foo.php", File.read(fixture_path("php_71_sample.php")))

      issues = run_engine(engine_conf).strip.split("\0")

      expect(issues.length).to eq(2)

      expect(JSON.parse(issues.first.strip)["location"]).to eq({
        "path" => "foo.php",
        "lines" => { "begin" => 2, "end" => 7 },
      })

      expect(JSON.parse(issues.last.strip)["location"]).to eq({
        "path" => "foo.php",
        "lines" => { "begin" => 11, "end" => 16 },
      })
    end
  end

  def engine_conf
    CC::Engine::Analyzers::EngineConfig.new({
      'config' => {
        'languages' => {
          'php' => {
            'mass_threshold' => 5,
          },
        },
      },
    })
  end
end
