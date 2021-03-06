require 'spec_helper'
require 'cc/engine/analyzers/analyzer_base'
require 'cc/engine/analyzers/engine_config'

module CC::Engine::Analyzers
  RSpec.describe Base, in_tmpdir: true do
    class DummyAnalyzer < Base
      LANGUAGE = "dummy"
      PATTERNS = [
        '**/*.a',
        '**/*.b'
      ]
    end

    include AnalyzerSpecHelpers

    let(:engine_config) { EngineConfig.new({}) }
    let(:analyzer) do
      DummyAnalyzer.new(
        engine_config: engine_config,
        parse_metrics: CC::Engine::ParseMetrics.new(
          language: "dummy",
          io: StringIO.new,
        ),
      )
    end

    before(:each) do
      create_source_file("foo.a", "")
      create_source_file("foo.b", "")
      create_source_file("foo.c", "")
    end

    it "lists files according to the default patterns" do
      expect(analyzer.files).to match_array(['./foo.a', './foo.b'])
    end

    it "knows what language it is analyzing" do
      expect(analyzer.language).to eq("dummy")
    end

    context "with custom patterns" do
      let(:engine_config) do
        EngineConfig.new({
          "config" => {
            "languages" => {
              "dummy" => {
                "patterns" => [
                  "**/*.c"
                ],
              },
            },
          },
        })
      end

      it "lists files according to the config patterns" do
        expect(analyzer.files).to match_array(['./foo.c'])
      end
    end

    context "exact pattern" do
      let(:engine_config) do
        EngineConfig.new({
          "config" => {
            "languages" => {
              "dummy" => {
                "patterns" => [
                  "*.c"
                ],
              },
            },
          },
        })
      end

      before(:each) do
        Dir.mkdir("nested")
        create_source_file("nested/foo.c", "")
      end

      it "lists files exactly according to the config patterns" do
        expect(analyzer.files).to match_array(['./foo.c'])
      end
    end
  end
end
