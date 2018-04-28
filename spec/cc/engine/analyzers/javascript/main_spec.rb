require 'spec_helper'
require 'cc/engine/analyzers/javascript/main'
require 'cc/engine/analyzers/reporter'
require 'cc/engine/analyzers/engine_config'

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
      expect(json["check_name"]).to eq("identical-code")
      expect(json["description"]).to eq("Identical blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.js",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(600_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.js", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.js", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 11/)
      expect(json["fingerprint"]).to eq("c4d29200c20d02297c6f550ad2c87c15")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
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
      expect(json["check_name"]).to eq("similar-code")
      expect(json["description"]).to eq("Similar blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.js",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(600_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.js", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.js", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 11/)
      expect(json["fingerprint"]).to eq("d9dab8e4607e2a74da3b9eefb49eacec")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
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

      expect(CC.logger).to receive(:warn).with(/Skipping \.\/foo\.js/)
      expect(CC.logger).to receive(:warn).with("Response status: 422")
      expect(run_engine(engine_conf)).to eq("")
    end

    it "skips minified files" do
      path = fixture_path("huge_js_file.js")
      create_source_file("foo.js", File.read(path))

      expect(CC.logger).to receive(:warn).with(/Skipping \.\/foo\.js/)
      expect(CC.logger).to receive(:warn).with("Response status: 422")
      expect(run_engine(engine_conf)).to eq("")
    end

    it "handles parser 500s" do
      create_source_file("foo.js", <<-EOJS)
      EOJS

      error = CC::Parser::Client::HTTPError.new(500, "Error processing file: ./foo.js")
      allow(CC::Parser).to receive(:parse).with("", "/javascript", filename: "./foo.js").and_raise(error)

      expect(CC.logger).to receive(:error).with("Error processing file: ./foo.js")
      expect(CC.logger).to receive(:error).with(error.message)

      expect { run_engine(engine_conf) }.to raise_error(error)
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

  it "ignores imports" do
    create_source_file("foo.js", <<~EOJS)
    import React, { Component, PropTypes } from 'react'
    import { Table, TableBody, TableHeader, TableHeaderColumn, TableRow } from 'material-ui/Table'
    import values from 'lodash/values'
    import { v4 } from 'uuid'
    EOJS

    create_source_file("bar.js", <<~EOJS)
    import React, { Component, PropTypes } from 'react'
    import { Table, TableBody, TableHeader, TableHeaderColumn, TableRow } from 'material-ui/Table'
    import values from 'lodash/values'
    import { v4 } from 'uuid'
    EOJS

    issues = run_engine(engine_conf).strip.split("\0")
    expect(issues).to be_empty
  end

  it "ignores requires" do
    create_source_file("foo.js", <<~EOJS)
    const a = require('foo'),
      b = require('bar'),
      c = require('baz'),
      d = require('bam');
    a + b + c + d;
    EOJS

    create_source_file("bar.js", <<~EOJS)
    const a = require('foo'),
      b = require('bar'),
      c = require('baz'),
      d = require('bam');
    print(a);
    EOJS

    issues = run_engine(engine_conf 3).strip.split("\0")
    expect(issues).to be_empty
  end

  it "outputs the correct line numbers for ASTs missing line details (codeclimate/app#6227)" do
    create_source_file("foo.js", <<~EOJS)
      `/movie?${getQueryString({ movie_id: movieId })}`
    EOJS

    create_source_file("bar.js", <<~EOJS)
      var greeting = "hello";

      `/movie?${getQueryString({ movie_id: movieId })}`
    EOJS

    issues = run_engine(engine_conf).strip.split("\0")
    expect(issues).to_not be_empty

    issues.map! { |issue| JSON.parse(issue) }

    foo_issue = issues.detect { |issue| issue.fetch("location").fetch("path") == "foo.js" }
    expect(foo_issue["location"]).to eq({
      "path" => "foo.js",
      "lines" => { "begin" => 1, "end" => 1 },
    })

    bar_issue = issues.detect { |issue| issue.fetch("location").fetch("path") == "bar.js" }
    expect(bar_issue["location"]).to eq({
      "path" => "bar.js",
      "lines" => { "begin" => 3, "end" => 3 },
    })
  end

  def engine_conf mass = 1
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
          'javascript' => {
            'mass_threshold' => mass,
          },
        },
      },
    })
  end
end
