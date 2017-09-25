require "spec_helper"
require "cc/engine/analyzers/java/main"
require "cc/engine/analyzers/engine_config"
require "cc/engine/analyzers/file_list"

module CC::Engine::Analyzers
  RSpec.describe Java::Main, in_tmpdir: true do
    include AnalyzerSpecHelpers

    describe "#run" do
      let(:engine_conf) { EngineConfig.new({}) }

      it "prints an issue for similar code" do
        create_source_file("foo.java", <<-EOF)
          public class ArrayDemo {
            public static void foo() {
              int[] anArray;

              anArray = new int[10];

              for (int i = 0; i < anArray.length; i++) {
                anArray[i] = i;
              }

              for (int i = 0; i < anArray.length; i++) {
                System.out.print(anArray[i] + " ");
              }

              System.out.println();
            }

            public static void bar() {
              int[] anArray;

              anArray = new int[10];

              for (int i = 0; i < anArray.length; i++) {
                anArray[i] = i;
              }

              for (int i = 0; i < anArray.length; i++) {
                System.out.print(anArray[i] + " ");
              }

              System.out.println();
            }
          }
        EOF

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("similar-code")
        expect(json["description"]).to eq("Similar blocks of code found in 2 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.java",
          "lines" => { "begin" => 2, "end" => 16 },
        })
        expect(json["remediation_points"]).to eq(930_000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.java", "lines" => { "begin" => 18, "end" => 32 } },
        ])
        expect(json["content"]["body"]).to match /This issue has a mass of 103/
        expect(json["fingerprint"]).to eq("48eb151dc29634f90a86ffabf9d3c4b5")
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
      end

      it "prints an issue for identical code" do
        create_source_file("foo.java", <<-EOF)
          public class ArrayDemo {
            public static void foo(int[] anArray) {
              for (int i = 0; i < anArray.length; i++) {
                System.out.print(anArray[i] + " ");
              }

              System.out.println();
            }

            public static void foo(int[] anArray) {
              for (int i = 0; i < anArray.length; i++) {
                System.out.print(anArray[i] + " ");
              }

              System.out.println();
            }
          }
        EOF

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("identical-code")
        expect(json["description"]).to eq("Identical blocks of code found in 2 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.java",
          "lines" => { "begin" => 2, "end" => 8 },
        })
        expect(json["remediation_points"]).to eq(420_000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.java", "lines" => { "begin" => 10, "end" => 16 } },
        ])
        expect(json["content"]["body"]).to match /This issue has a mass of 52/
        expect(json["fingerprint"]).to eq("dbb957b34f7b5312538235c0aa3f52a0")
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MINOR)
      end

      it "outputs a warning for unprocessable errors" do
        create_source_file("foo.java", <<-EOF)
          ---
        EOF

        expect(CC.logger).to receive(:warn).with(/Response status: 422/)
        expect(CC.logger).to receive(:warn).with(/Skipping/)
        run_engine(engine_conf)
      end

      it "ignores import and package declarations" do
        create_source_file("foo.java", <<-EOF)
package org.springframework.rules.constraint;

import java.util.Comparator;

import org.springframework.rules.constraint.Constraint;
import org.springframework.rules.closure.BinaryConstraint;
        EOF

        create_source_file("bar.java", <<-EOF)
package org.springframework.rules.constraint;

import java.util.Comparator;

import org.springframework.rules.constraint.Constraint;
import org.springframework.rules.closure.BinaryConstraint;
        EOF

        issues = run_engine(engine_conf).strip.split("\0")
        expect(issues).to be_empty
      end

      it "prints an issue for similar code when the only difference is the value of a literal" do
        create_source_file("foo.java", <<-EOF)
          public class ArrayDemo {
            public static void foo() {
              int[] scott;
              scott = new int[] {
                0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F
              };

              int[] anArray;

              anArray = new int[10];

              for (int i = 0; i < anArray.length; i++) {
                anArray[i] = i;
              }

              for (int i = 0; i < anArray.length; i++) {
                System.out.print(anArray[i] + " ");
              }

              System.out.println();
            }

            public static void foo() {
              int[] scott;
              scott = new int[] {
                0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7
              };

              int[] anArray;

              anArray = new int[10];

              for (int i = 0; i < anArray.length; i++) {
                anArray[i] = i;
              }

              for (int i = 0; i < anArray.length; i++) {
                System.out.print(anArray[i] + " ");
              }

              System.out.println();
            }
          }
        EOF

        issues = run_engine(engine_conf).strip.split("\0")
        expect(issues.length).to be > 0
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("similar-code")

        expect(json["description"]).to eq("Similar blocks of code found in 2 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.java",
          "lines" => { "begin" => 2, "end" => 21 },
        })
        expect(json["remediation_points"]).to eq(1_230_000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.java", "lines" => { "begin" => 23, "end" => 42 } },
        ])
        expect(json["content"]["body"]).to match /This issue has a mass of 133/
        expect(json["fingerprint"]).to eq("9abf88bac3a56bf708a5c4ceaf251d98")
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
      end
    end
  end
end
