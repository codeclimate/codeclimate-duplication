require 'spec_helper'
require 'cc/engine/analyzers/javascript/main'
require 'cc/engine/analyzers/reporter'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'

RSpec.describe CC::Engine::Analyzers::Javascript::Main, in_tmpdir: true do
  include AnalyzerSpecHelpers

  describe "#run" do
    it "prints an issue for identical code" do
      create_source_file("foo.js", <<-EOJS)
          console.log("hello JS!");
          console.log("hello JS!");
          console.log("hello JS!");
      EOJS

      issues = run_engine(engine_conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Identical code")
      expect(json["description"]).to eq("Identical code found in 2 other locations (mass = 11)")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.js",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(1_800_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.js", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.js", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 11/)
      expect(json["fingerprint"]).to eq("c4d29200c20d02297c6f550ad2c87c15")
    end

    it "prints an issue for similar code" do
      create_source_file("foo.js", <<-EOJS)
          console.log("hello JS!");
          console.log("hellllllo JS!");
          console.log("helllllllllllllllllo JS!");
      EOJS

      issues = run_engine(engine_conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Similar code")
      expect(json["description"]).to eq("Similar code found in 2 other locations (mass = 11)")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.js",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(1_800_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.js", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.js", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 11/)
      expect(json["fingerprint"]).to eq("d9dab8e4607e2a74da3b9eefb49eacec")
    end

    it "handles ES6 spread params" do
      create_source_file("foo.jsx", <<-EOJS)
        const ThingClass = React.createClass({
          propTypes: {
            ...OtherThing.propTypes,
            otherProp: "someVal"
          }
        });
      EOJS


      expect(CC.logger).not_to receive(:info).with(/Skipping file/)
      run_engine(engine_conf)
    end

    it "skips unparsable files" do
      create_source_file("foo.js", <<-EOJS)
        function () { do(); // missing closing brace
      EOJS

      expect(CC.logger).to receive(:info).with(/Skipping file/)
      expect(run_engine(engine_conf)).to eq("")
    end

    it "skips minified files" do
      path = fixture_path("huge_js_file.js")
      create_source_file("foo.js", File.read(path))

      expect(CC.logger).to receive(:info).with(/Skipping file/)
      expect(run_engine(engine_conf)).to eq("")
    end
  end

  it "does not flag duplicate comments" do
      create_source_file("foo.js", <<-EOJS)
        // A comment.
        // A comment.

        /* A comment. */
        /* A comment. */
      EOJS

      expect(run_engine(engine_conf)).to be_empty
  end

  it "does not report the same line for multiple issues" do
    create_source_file("dup.jsx", <<-EOJSX)
<a className='button button-primary full' href='#' onClick={this.onSubmit.bind(this)}>Login</a>
    EOJSX

    issues = run_engine(engine_conf).strip.split("\0")

    expect(issues.length).to eq 1
  end

  def engine_conf
    CC::Engine::Analyzers::EngineConfig.new({
      'config' => {
        'languages' => {
          'javascript' => {
            'mass_threshold' => 1,
          },
        },
      },
    })
  end
end
