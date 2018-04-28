require "spec_helper"
require "cc/engine/analyzers/go/main"
require 'cc/engine/analyzers/reporter'
require "cc/engine/analyzers/engine_config"

module CC::Engine::Analyzers
  RSpec.describe Go::Main, in_tmpdir: true do
    include AnalyzerSpecHelpers

    describe "#run" do
      it "prints an issue for identical code" do
        create_source_file("foo.go", <<-EOGO)
          package main

          import "fmt"

          func main() {
            fmt.Println(add(24, 24))
            fmt.Println(add(24, 24))
          }

          func add(x int, y int) int {
            return x + y
          }
        EOGO

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("identical-code")
        expect(json["description"]).to eq("Identical blocks of code found in 2 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.go",
          "lines" => { "begin" => 6, "end" => 6 },
        })
        expect(json["remediation_points"]).to eq(360_000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.go", "lines" => { "begin" => 7, "end" => 7} },
        ])
        expect(json["content"]["body"]).to match(/This issue has a mass of 16/)
        expect(json["fingerprint"]).to eq("484ee5799eb0e6c933751cfa85ba33c3")
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MINOR)
      end

      it "prints an issue for similar code" do
        create_source_file("foo.go", <<-EOGO)
          package main

          import "fmt"

          func add(x int, y int) int {
            return x + y
          }

          func add_something(x int, y int) int {
            return x + y
          }

          func add_something_else(x int, y int) int {
            return x + y
          }

          func main() {
            fmt.Println(add(44, 15))
            fmt.Println(add_something(44, 15))
            fmt.Println(add_something_else(44, 15))
          }
        EOGO

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("similar-code")
        expect(json["description"]).to eq("Similar blocks of code found in 3 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.go",
          "lines" => { "begin" => 5, "end" => 7 },
          })
        expect(json["remediation_points"]).to eq(540_000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.go", "lines" => { "begin" => 9, "end" => 11} },
          {"path" => "foo.go", "lines" => { "begin" => 13, "end" => 15} },
        ])
        expect(json["content"]["body"]).to match /This issue has a mass of 34/
        expect(json["fingerprint"]).to eq("ed3f2dbc039a394ad03d16e4d9f342fe")
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
      end

      it "outputs a warning for unprocessable errors" do
        create_source_file("foo.go", <<-EOGO)
          ---
        EOGO

        expect(CC.logger).to receive(:warn).with(/Response status: 422/)
        expect(CC.logger).to receive(:warn).with(/Skipping/)
        run_engine(engine_conf)
      end

      it "ignores import declarations" do
        create_source_file("foo.go", <<-EOGO)
          package main

          import "fmt"

          func main() {
            fmt.Println("This is a thing")
          }
        EOGO

        create_source_file("bar.go", <<-EOGO)
          package main

          import "fmt"

          func main() {
            fmt.Println("This is something else!")
          }
        EOGO

        issues = run_engine(engine_conf 25).strip.split("\0")
        expect(issues).to be_empty
      end

      it "does not flag entire file as issue" do
        create_source_file("foo.go", File.read(fixture_path("issue_6609_1.go")))
        create_source_file("bar.go", File.read(fixture_path("issue_6609_2.go")))
        issues = run_engine(engine_conf).strip.split("\0")
        issues.map! {|issue| JSON.parse issue}
        invalid_issues = issues.find_all{|issue| issue["location"]["lines"]["begin"] == 1}
        expect(invalid_issues).to be_empty, invalid_issues.map {|issue| issue["location"]}.join("\n")
      end

      it "does not flag duplicate comments" do
        create_source_file("foo.go", <<-EOGO)
          // This is a comment.
          // This is a comment.
          // This is a comment.
          // This is also a comment.
          // This is also a comment.

          package main

          // import "fmt"

          func main() {
            fmt.Println("This is a duplicate!")
          }

          /* This is a multiline comment */
          /* This is a multiline comment */
          /* This is a also multiline comment */
          /* This is a also multiline comment */

          // func add(x int, y int) int {
          //   return x + y
          // }

          // func add(x int, y int) int {
          //   return x + y
          // }

          // func add(x int, y int) int {
          //   return x + y
          // }

          // func add(x int, y int) int {
          //   return x + y
          // }
        EOGO

        create_source_file("bar.go", <<-EOGO)
          // This is a comment.
          // This is a comment.
          // This is a comment.
          // This is also a comment.
          // This is also a comment.

          package main

          // import "fmt"

          func main() {
            // This is a comment.
            // This is a comment.
            // This is a comment.
            // This is also a comment.
            // This is also a comment.
          }

          /* This is a multiline comment */
          /* This is a multiline comment */
          /* This is a also multiline comment */
          /* This is a also multiline comment */

          // func add(x int, y int) int {
          //   return x + y
          // }

          // func add(x int, y int) int {
          //   return x + y
          // }

          // func add(x int, y int) int {
          //   return x + y
          // }

          // func add(x int, y int) int {
          //   return x + y
          // }
        EOGO

        expect(run_engine(engine_conf)).to be_empty
      end

      def engine_conf mass = 10
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
              'go' => {
                'mass_threshold' => mass,
              },
            },
          },
        })
      end
    end
  end
end
