require 'cc/engine/analyzers/php/main'
require 'cc/engine/analyzers/reporter'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'
require 'flay'
require 'tmpdir'

RSpec.describe CC::Engine::Analyzers::Php::Main, in_tmpdir: true do
  include AnalyzerSpecHelpers

  describe "#run" do
    it "prints an issue" do

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

      result = run_engine(engine_conf).strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Identical code")
      expect(json["description"]).to eq("Similar code found in 1 other location")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.php",
        "lines" => { "begin" => 2, "end" => 6 },
      })
      expect(json["remediation_points"]).to eq(176000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.php", "lines" => { "begin" => 10, "end" => 14} },
      ])
      expect(json["content"]["body"]).to match /This issue has a mass of `44`/
      expect(json["fingerprint"]).to eq("667da0e2bab866aa2fe9d014a65d57d9")
    end
  end

  def printed_issue
    issue = {"type":"issue","check_name":"Identical code","description":"Similar code found in 1 other location","categories":["Duplication"],"location":{"path":"foo.php","lines":{"begin":2,"end":6}},"remediation_points":176000,"other_locations":[{"path":"foo.php","lines":{"begin":10,"end":14}}],"content":{"body": read_up}}
    issue.to_json + "\0\n"
  end

  def engine_conf
    CC::Engine::Analyzers::EngineConfig.new({
      'config' => {
        'languages' => {
          'php' => {
            'mass_threshold' => 5
          }
        }
      }
    })
  end
end
