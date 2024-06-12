require 'spec_helper'
require 'cc/engine/analyzers/php/main'
require 'cc/engine/analyzers/reporter'
require 'cc/engine/analyzers/engine_config'

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

          function hello($name) {
            if (empty($name)) {
              echo "Hello World!";
            } else {
              echo "Hello $name!";
            }
          }
      EOPHP

      issues = run_engine(engine_conf).strip.split("\0")
      expect(issues.length).to be > 0
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("identical-code")
      expect(json["description"]).to eq("Identical blocks of code found in 2 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.php",
        "lines" => { "begin" => 2, "end" => 8 },
      })
      expect(json["remediation_points"]).to eq(967000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.php", "lines" => { "begin" => 10, "end" => 16} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 28/)
      expect(json["fingerprint"]).to eq("b41447552cff977d3d98dff4cd282ec2")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
    end

    it "prints an issue for similar code" do
      create_source_file("foo.php", <<-EOPHP)
          <?php
          function hello($name) {
            if (empty($name)) {
              echo "Hello World!";
            } else {
              echo "Hello $name!";
            }
          }

          function hi($nickname) {
            if (empty($nickname)) {
              echo "Hi World!";
            } else {
              echo "Hi $nickname!";
            }
          }
      EOPHP

      issues = run_engine(engine_conf).strip.split("\0")
      expect(issues.length).to be > 0
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("similar-code")
      expect(json["description"]).to eq("Similar blocks of code found in 2 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.php",
        "lines" => { "begin" => 2, "end" => 8 },
      })
      expect(json["remediation_points"]).to eq(967000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.php", "lines" => { "begin" => 10, "end" => 16} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 28/)
      expect(json["fingerprint"]).to eq("c4c0b456f59f109d0a5cfce7d4807935")
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

      expect(CC.logger).to receive(:warn).with(/Skipping \.\/foo.php/)
      expect(CC.logger).to receive(:warn).with(/Response status: 422/)

      expect(run_engine(engine_conf)).to eq("")
    end

    it "can parse php 7 code" do
      create_source_file("foo.php", File.read(fixture_path("from_phan_php7.php")))
      issues = run_engine(engine_conf).strip.split("\0")
      expect(issues.length).to be > 0
      result = issues.first.strip
      json = JSON.parse(result)
      expect(json["location"]).to eq({
        "path" => "foo.php",
        "lines" => { "begin" => 190, "end" => 190 },
      })
    end

    it "can parse php 7.1 code" do
      create_source_file("foo.php", File.read(fixture_path("php_71_sample.php")))

      issues = run_engine(engine_conf).strip.split("\0")

      expect(issues.length).to eq(2)

      expect(JSON.parse(issues.first.strip)["location"]).to eq({
        "path" => "foo.php",
        "lines" => { "begin" => 2, "end" => 9 },
      })

      expect(JSON.parse(issues.last.strip)["location"]).to eq({
        "path" => "foo.php",
        "lines" => { "begin" => 11, "end" => 18 },
      })
    end

    it "ignores namespace and use declarations" do
      create_source_file("foo.php", <<~EOPHP)
      <?php
      namespace KeepClear\\Http\\Controllers\\API\\V1;

      use Illuminate\\Http\\Request;
      use KeepClear\\Http\\Controllers\\Controller;
      use KeepClear\\Models\\Comment;
      use KeepClear\\Models\\User;
      use KeepClear\\Models\\Asset;
      use KeepClear\\Traits\\Controllers\\ApiFilter;
      use KeepClear\\Traits\\Controllers\\ApiParseBody;
      use KeepClear\\Traits\\Controllers\\ApiException;
      
      a / b;
      EOPHP

      create_source_file("bar.php", <<~EOPHP)
      <?php
      namespace KeepClear\\Http\\Controllers\\API\\V1;

      use Illuminate\\Http\\Request;
      use KeepClear\\Http\\Controllers\\Controller;
      use KeepClear\\Models\\Comment;
      use KeepClear\\Models\\User;
      use KeepClear\\Models\\Asset;
      use KeepClear\\Traits\\Controllers\\ApiFilter;
      use KeepClear\\Traits\\Controllers\\ApiParseBody;
      use KeepClear\\Traits\\Controllers\\ApiException;

      a + b;
      EOPHP

      issues = run_engine(engine_conf 6).strip.split("\0")
      expect(issues).to be_empty
    end

    context "comments" do
      it "ignores PHPDoc comments" do
        create_source_file("foo.php", <<-EOPHP)
          <?php

          /**
           * Says "hello"
           *
           * @param string $name
           */
          function hello($name) {
            if (empty($name)) {
              echo "Hello World!";
            } else {
              echo "Hello $name!";
            }
          }

          /**
           * Says "hi"
           *
           * @param string $nickname
           */
          function hi($nickname) {
            if (empty($nickname)) {
              echo "Hi World!";
            } else {
              echo "Hi $nickname!";
            }
          }
        EOPHP

        issues = run_engine(engine_conf).strip.split("\0")
        expect(issues.length).to be > 0

        issue = JSON.parse(issues.first.strip)
        expect(issue["location"]).to eq(
          "path" => "foo.php",
          "lines" => { "begin" => 8, "end" => 14 },
        )
        expect(issue["content"]["body"]).to match(/This issue has a mass of 28/)
      end

      it "ignores one-line comments" do
        create_source_file("foo.php", <<-EOPHP)
          <?php

          // Says "hello"
          function hello($name) {
            if (empty($name)) {
              echo "Hello World!";
            } else {
              echo "Hello $name!";
            }
          }

          // Says "hi"
          function hi($nickname) {
            if (empty($nickname)) {
              echo "Hi World!";
            } else {
              echo "Hi $nickname!";
            }
          }
        EOPHP

        issues = run_engine(engine_conf).strip.split("\0")
        expect(issues.length).to be > 0

        issue = JSON.parse(issues.first.strip)
        expect(issue["location"]).to eq(
          "path" => "foo.php",
          "lines" => { "begin" => 4, "end" => 10 },
        )
        expect(issue["content"]["body"]).to match(/This issue has a mass of 28/)
      end
    end
  end

  def engine_conf mass = 5
    CC::Engine::Analyzers::EngineConfig.new({
      'config' => {
        'languages' => {
          'php' => {
            'mass_threshold' => mass,
          },
        },
      },
    })
  end
end
