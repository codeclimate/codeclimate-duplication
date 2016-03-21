require "spec_helper"
require "cc/engine/analyzers/file_list"
require "cc/engine/analyzers/engine_config"

RSpec.describe CC::Engine::Analyzers::FileList do
  around do |example|
    Dir.mktmpdir do |directory|
      @tmp_dir = directory

      Dir.chdir(@tmp_dir) do
        Dir.mkdir("nested")
        File.write(File.join(@tmp_dir, "nested", "nest.hs"), "")

        File.write(File.join(@tmp_dir, "foo.js"), "")
        File.write(File.join(@tmp_dir, "foo.jsx"), "")
        File.write(File.join(@tmp_dir, "foo.ex"), "")

        example.run
      end
    end
  end

  describe "#files" do
    it "expands patterns for directory includes" do
      file_list = ::CC::Engine::Analyzers::FileList.new(
        engine_config: CC::Engine::Analyzers::EngineConfig.new(
          "include_paths" => ["./"],
        ),
        patterns: ["**/*.js", "**/*.jsx"],
      )

      expect(file_list.files).to eq(["./foo.js", "./foo.jsx"])
    end

    it "filters file includes by patterns" do
      file_list = ::CC::Engine::Analyzers::FileList.new(
        engine_config: CC::Engine::Analyzers::EngineConfig.new(
          "include_paths" => ["./foo.ex", "./foo.js"],
        ),
        patterns: ["**/*.js", "**/*.jsx"],
      )

      expect(file_list.files).to eq(["./foo.js"])
    end
  end
end
