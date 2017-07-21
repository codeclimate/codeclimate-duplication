require 'spec_helper'
require 'cc/engine/analyzers/java/main'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'

module CC::Engine::Analyzers
  RSpec.describe Java::Main, in_tmpdir: true do
    include AnalyzerSpecHelpers

    describe "#run" do
      it "returns similar code issues for java" do
        create_source_file("foo.java", <<-EOJAVA)
          public class Dog {
            void bark(Boolean jumpToo) {
              if (jumpToo) {
                barkAndJump();
              } else if (true == true) {
                foo();
              } else if (false == false) {
                bar();
              } else if (true == true) {
                foo();
              } else if (false == false) {
                bar();
              } else if (true == true) {
                foo();
              } else if (false == false) {
                bar();
              } else {
                justBark();
              }
            }

            void bark(Boolean jumpToo) {
              if (jumpToo) {
                barkAndJump();
              } else if (true == true) {
                foo();
              } else if (false == false) {
                bar();
              } else if (true == true) {
                foo();
              } else if (false == false) {
                bar();
              } else if (true == true) {
                foo();
              } else if (false == false) {
                bar();
              } else {
                justBark();
              }
            }
          }
        EOJAVA

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("Identical code")
      end
    end

    def engine_conf(opts = {})
      CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "java" => {
              "mass_threshold" => 2,
            }.merge(opts),
          },
        },
      })
    end
  end
end
