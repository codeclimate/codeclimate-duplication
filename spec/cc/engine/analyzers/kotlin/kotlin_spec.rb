require "spec_helper"
require "cc/engine/analyzers/kotlin/main"
require "cc/engine/analyzers/engine_config"

module CC::Engine::Analyzers
  RSpec.describe Kotlin::Main, in_tmpdir: true do
    include AnalyzerSpecHelpers

    describe "#run" do
      let(:engine_conf) { EngineConfig.new({}) }

      it "prints an issue for similar code" do
        create_source_file("foo.kt", <<-EOF)
          class ArrayDemo {
            fun foo() {
              val anArray: Array<Int> = Array(10)

              for (i in 0..10) {
                anArray[i] = i
              }

              for (i in 0..10) {
                println(anArray[i])
              }

              println("")
            }

            fun bar() {
              val anArray: Array<Int> = Array(10)

              for (i in 0..10) {
                anArray[i] = i
              }

              for (i in 0..10) {
                println(anArray[i])
              }

              println("")
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
          "path" => "foo.kt",
          "lines" => { "begin" => 2, "end" => 14 },
        })
        expect(json["other_locations"]).to eq([
          {"path" => "foo.kt", "lines" => { "begin" => 16, "end" => 28 } },
        ])
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
      end

      it "prints an issue for identical code" do
        create_source_file("foo.kt", <<-EOF)
          class ArrayDemo {
            fun foo(anArray: Array<Int>) {
              for (i in anArray.indices) {
                println(anArray[i] + " ")
              }

              println("")
            }

            fun foo(anArray: Array<Int>) {
              for (i in anArray.indices) {
                println(anArray[i] + " ")
              }

              println("")
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
          "path" => "foo.kt",
          "lines" => { "begin" => 2, "end" => 8 },
        })
        expect(json["other_locations"]).to eq([
          {"path" => "foo.kt", "lines" => { "begin" => 10, "end" => 16 } },
        ])
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
      end

      it "outputs a warning for unprocessable errors" do
        create_source_file("foo.kt", <<-EOF)
          ---
        EOF

        expect(CC.logger).to receive(:warn).with(/Response status: 422/)
        expect(CC.logger).to receive(:warn).with(/Skipping/)
        run_engine(engine_conf)
      end

      it "ignores import and package declarations" do
        create_source_file("foo.kt", <<-EOF)
          package org.springframework.rules.constraint;

          import java.util.Comparator;

          import org.springframework.rules.constraint.Constraint;
          import org.springframework.rules.closure.BinaryConstraint;
        EOF

        create_source_file("bar.kt", <<-EOF)
          package org.springframework.rules.constraint;

          import java.util.Comparator;

          import org.springframework.rules.constraint.Constraint;
          import org.springframework.rules.closure.BinaryConstraint;
        EOF

        issues = run_engine(engine_conf).strip.split("\0")
        expect(issues).to be_empty
      end

      it "prints an issue for similar code when the only difference is the value of a literal" do
        create_source_file("foo.kt", <<-EOF)
          class ArrayDemo {
            fun foo() {
              val scott = arrayOfInt(
                0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F
              )

              val anArray: Array<Int> = Array(10)

              for (i in 0..10) {
                anArray[i] = i
              }

              for (i in 0..10) {
                println(anArray[i] + " ")
              }

              println()
            }

            fun foo() {
              val scott = arrayOfInt(
                0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7
              )

              val anArray: Array<Int> = Array(10)

              for (i in 0..10) {
                anArray[i] = i
              }

              for (i in 0..10) {
                println(anArray[i] + " ")
              }

              println()
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
          "path" => "foo.kt",
          "lines" => { "begin" => 2, "end" => 18 },
        })
        expect(json["other_locations"]).to eq([
          {"path" => "foo.kt", "lines" => { "begin" => 20, "end" => 36 } },
        ])
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MAJOR)
      end

      it "ignores comment docs and comments" do
        create_source_file("foo.kt", <<-EOF)
           /********************************************************************
            *  Copyright (C) 2017 by Max Lv <max.c.lv@gmail.com>
            *******************************************************************/

           package com.github.shadowsocks.acl
           // Comment here

           import org.junit.Assert
           import org.junit.Test

           class AclTest {
               // Comment here
               companion object {
                   private const val INPUT1 = """[proxy_all]
           [bypass_list]
           1.0.1.0/24
           (^|\.)4tern\.com${'$'}
           """
               }

               @Test
               fun parse() {
                   Assert.assertEquals(INPUT1, Acl().fromReader(INPUT1.reader()).toString());
               }
           }
        EOF

        create_source_file("bar.kt", <<-EOF)
          /*********************************************************************
           *  Copyright (C) 2017 by Max Lv <max.c.lv@gmail.com>
           ********************************************************************/

          package com.evernote.android.job
          // Comment here

          object JobConstants {
              // Comment here
              const val DATABASE_NAME = JobStorage.DATABASE_NAME
              const val PREF_FILE_NAME = JobStorage.PREF_FILE_NAME
          }
        EOF

        issues = run_engine(engine_conf).strip.split("\0")
        expect(issues).to be_empty
      end

    end
  end
end
