require 'spec_helper'
require 'cc/engine/analyzers/typescript/main'
require 'cc/engine/analyzers/reporter'
require 'cc/engine/analyzers/engine_config'

RSpec.describe CC::Engine::Analyzers::TypeScript::Main, in_tmpdir: true do
  include AnalyzerSpecHelpers

  describe "#run" do
    it "prints an issue for identical code" do
      create_source_file("foo.ts", <<-EOTS)
          enum Direction { Up = "UP", Down = "DOWN", Left = "LEFT", Right = "RIGHT" }
          enum Direction { Up = "UP", Down = "DOWN", Left = "LEFT", Right = "RIGHT" }
          enum Direction { Up = "UP", Down = "DOWN", Left = "LEFT", Right = "RIGHT" }
      EOTS

      issues = run_engine(engine_conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("identical-code")
      expect(json["description"]).to eq("Identical blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.ts",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(990_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.ts", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.ts", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 24/)
      expect(json["fingerprint"]).to eq("a53b767d2f602f832540ef667ca0618f")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
    end

    it "prints an issue for similar code" do
      create_source_file("foo.ts", <<-EOTS)
          enum Direction { Up = "UP", Down = "DOWN", Left = "LEFT", Right = "RIGHT" }
          enum Direction { Up = "up", Down = "down", Left = "left", Right = "right" }
          enum Direction { up = "UP", down = "DOWN", left = "LEFT", right = "RIGHT" }
      EOTS

      issues = run_engine(engine_conf).strip.split("\0")
      result = issues.first.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("similar-code")
      expect(json["description"]).to eq("Similar blocks of code found in 3 locations. Consider refactoring.")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.ts",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(990_000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.ts", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.ts", "lines" => { "begin" => 3, "end" => 3} },
      ])
      expect(json["content"]["body"]).to match(/This issue has a mass of 24/)
      expect(json["fingerprint"]).to eq("ede3452b637e0bc021541e6369b9362e")
      expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
    end

    it "handles ES6 spread params" do
      create_source_file("foo.tsx", <<-EOTS)
        const ThingClass = React.createClass({
          propTypes: {
            ...OtherThing.propTypes,
            otherProp: "someVal"
          }
        });
      EOTS

      expect(CC.logger).not_to receive(:info).with(/Skipping file/)
      run_engine(engine_conf)
    end

    it "skips unparsable files" do
      create_source_file("foo.ts", <<-EOTS)
        function () { do(); // missing closing brace
      EOTS

      expect(CC.logger).to receive(:warn).with(/Skipping \.\/foo\.ts/)
      expect(CC.logger).to receive(:warn).with("Response status: 422")
      expect(run_engine(engine_conf)).to eq("")
    end

    it "handles parser 500s" do
      create_source_file("foo.ts", <<-EOTS)
      EOTS

      error = CC::Parser::Client::HTTPError.new(500, "Error processing file: ./foo.ts")
      allow(CC::Parser).to receive(:parse).with("", "/typescript", filename: "./foo.ts").and_raise(error)

      expect(CC.logger).to receive(:error).with("Error processing file: ./foo.ts")
      expect(CC.logger).to receive(:error).with(error.message)

      expect { run_engine(engine_conf) }.to raise_error(error)
    end
  end

  it "does not flag duplicate comments" do
      create_source_file("foo.ts", <<-EOTS)
        // A comment.
        // A comment.

        /* A comment. */
        /* A comment. */
      EOTS

      expect(run_engine(engine_conf)).to be_empty
  end

  it "ignores imports" do
    create_source_file("foo.ts", <<~EOTS)
    import React, { Component, PropTypes } from 'react'
    import { Table, TableBody, TableHeader, TableHeaderColumn, TableRow } from 'material-ui/Table'
    import values from 'lodash/values'
    import { v4 } from 'uuid'
    EOTS

    create_source_file("bar.ts", <<~EOTS)
    import React, { Component, PropTypes } from 'react'
    import { Table, TableBody, TableHeader, TableHeaderColumn, TableRow } from 'material-ui/Table'
    import values from 'lodash/values'
    import { v4 } from 'uuid'
    EOTS

    issues = run_engine(engine_conf).strip.split("\0")
    expect(issues).to be_empty
  end

  it "ignores requires" do
    create_source_file("foo.ts", <<~EOTS)
    const a = require('foo'),
      b = require('bar'),
      c = require('baz'),
      d = require('bam');
    EOTS

    create_source_file("bar.ts", <<~EOTS)
    const a = require('foo'),
      b = require('bar'),
      c = require('baz'),
      d = require('bam');
    EOTS

    issues = run_engine(engine_conf).strip.split("\0")
    expect(issues).to be_empty
  end

  it "outputs the correct line numbers for ASTs missing line details (codeclimate/app#6227)" do
    create_source_file("foo.ts", <<~EOTS)
      `/movie?${getQueryString({ movie_id: movieId })}`
    EOTS

    create_source_file("bar.ts", <<~EOTS)
      var greeting = "hello";

      `/movie?${getQueryString({ movie_id: movieId })}`
    EOTS

    issues = run_engine(engine_conf).strip.split("\0")
    expect(issues).to_not be_empty

    issues.map! { |issue| JSON.parse(issue) }

    foo_issue = issues.detect { |issue| issue.fetch("location").fetch("path") == "foo.ts" }
    expect(foo_issue["location"]).to eq({
      "path" => "foo.ts",
      "lines" => { "begin" => 1, "end" => 1 },
    })

    bar_issue = issues.detect { |issue| issue.fetch("location").fetch("path") == "bar.ts" }
    expect(bar_issue["location"]).to eq({
      "path" => "bar.ts",
      "lines" => { "begin" => 3, "end" => 3 },
    })
  end

  it "supports TypeScript+React files" do
    create_source_file("foo.tsx", <<~EOTS)
      function ComponentFoo(prop: FooProp) {
        return <SomeComponent name="prop.name" />;
      }

      function ComponentFoo(prop: FooProp) {
        return <AnotherComponent name="prop.name" />;
      }
    EOTS

    issues = run_engine(engine_conf).strip.split("\0")
    result = issues.first.strip
    json = JSON.parse(result)

    expect(json["type"]).to eq("issue")
    expect(json["check_name"]).to eq("similar-code")
    expect(json["location"]).to eq({
      "path" => "foo.tsx",
      "lines" => { "begin" => 1, "end" => 3 },
    })
    expect(json["other_locations"]).to eq([
      {"path" => "foo.tsx", "lines" => { "begin" => 5, "end" => 7 } }
    ])
    expect(json["fingerprint"]).to eq("d8f0315c3c4e9ba81003a7ec6c823fb0")
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
          'typescript' => {
            'mass_threshold' => 1,
          },
        },
      },
    })
  end
end
