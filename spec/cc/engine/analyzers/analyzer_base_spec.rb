require 'spec_helper'
require 'cc/engine/analyzers/analyzer_base'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'

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
    let(:analyzer) { DummyAnalyzer.new(engine_config: engine_config) }

    before(:each) do
      create_source_file("foo.a", "")
      create_source_file("foo.b", "")
      create_source_file("foo.c", "")
    end

    it "lists files according to the default patterns" do
      expect(analyzer.files).to match_array(['./foo.a', './foo.b'])
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
