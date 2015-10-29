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
    it "returns files from default_paths when language is missing paths" do
      file_list = ::CC::Engine::Analyzers::FileList.new(
        engine_config: CC::Engine::Analyzers::EngineConfig.new({}),
        default_paths: ["**/*.js", "**/*.jsx"],
        language: "javascript",
      )

      expect(file_list.files).to eq(["./foo.js", "./foo.jsx"])
    end

    it "returns files from engine config defined paths when present" do
      file_list = ::CC::Engine::Analyzers::FileList.new(
        engine_config: CC::Engine::Analyzers::EngineConfig.new({
          "config" => {
            "languages" => {
              "elixir" => {
                "paths" => ["**/*.ex"]
              }
            }
          }
        }),
        default_paths: ["**/*.js", "**/*.jsx"],
        language: "elixir",
      )

      expect(file_list.files).to eq(["./foo.ex"])
    end

    it "returns files from default_paths when languages is an array" do
      file_list = ::CC::Engine::Analyzers::FileList.new(
        engine_config: CC::Engine::Analyzers::EngineConfig.new({
          "config" => {
            "languages" => [
              "elixir"
            ],
          },
        }),
        default_paths: ["**/*.js", "**/*.jsx"],
        language: "javascript",
      )

      expect(file_list.files).to eq(["./foo.js", "./foo.jsx"])
    end

    it "excludes files not in include_paths" do
      file_list = ::CC::Engine::Analyzers::FileList.new(
        engine_config: CC::Engine::Analyzers::EngineConfig.new({
          "include_paths" => ["foo.jsx", "nested"],
          "config" => {
            "languages" => [
              "elixir"
            ],
          },
        }),
        default_paths: ["**/*.js", "**/*.jsx", "**/*.hs"],
        language: "javascript",
      )

      expect(file_list.files).to eq(["./foo.jsx", "./nested/nest.hs"])
    end
  end
end
