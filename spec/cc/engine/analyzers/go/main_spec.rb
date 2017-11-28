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
              some_string()
          }

          func some_string() {
              fmt.Println("this is a string")
              fmt.Println("this is a string")
          }

          func some_string() {
              fmt.Println("this is a string")
              fmt.Println("this is a string")
          }
        EOGO

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
        create_source_file("foo.go", <<-EOGO)
          package main

          import "fmt"

          func add(x int, y int) int {
          	return x + y
            fmt.Println("Add some stuff!")
          }

          func add(x int, y int) int {
            return x + y
            fmt.Println("Add all the stuff!")
          }

          func main() {
          	fmt.Println(add(42, 13))
          }
        EOGO

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("similar-code")
        expect(json["description"]).to eq("Similar blocks of code found in 2 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.go",
          "lines" => { "begin" => 5, "end" => 8 },
          })
        expect(json["remediation_points"]).to eq(1_900_000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.go", "lines" => { "begin" => 10, "end" => 13} },
        ])
        expect(json["content"]["body"]).to match /This issue has a mass of 45/
        expect(json["fingerprint"]).to eq("f1551c88ceadf1241f6a0c92cce82413")
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

      it "ignores import and package declarations" do
        create_source_file("foo.go", <<-EOGO)
          package main
          package main

          import "fmt"
          import "fmt"
          import "fmt"

          func main() {
            fmt.Println("Hello!")
          }
        EOGO

        issues = run_engine(engine_conf).strip.split("\0")
        expect(issues).to be_empty
      end

      it "does not flag duplicate comments" do
        create_source_file("foo.go", <<-EOGO)
          // This is a comment.
          // This is a comment.
        EOGO

        expect(run_engine(engine_conf)).to be_empty
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
              'go' => {
                'mass_threshold' => 5,
              },
            },
          },
        })
      end
    end
  end
end
