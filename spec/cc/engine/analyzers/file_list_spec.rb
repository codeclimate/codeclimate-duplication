require "spec_helper"
require "cc/engine/analyzers/file_list"
require "cc/engine/analyzers/engine_config"

module CC::Engine::Analyzers
  describe FileList do
    before do
      @tmp_dir = Dir.mktmpdir
      Dir.chdir(@tmp_dir)

      File.write(File.join(@tmp_dir, "foo.js"), "")
      File.write(File.join(@tmp_dir, "foo.jsx"), "")
      File.write(File.join(@tmp_dir, "foo.ex"), "")
    end

    after do
      FileUtils.rm_rf(@tmp_dir)
    end

    describe "#files" do
      it "returns files from default_paths when language is missing paths" do
        file_list = ::CC::Engine::Analyzers::FileList.new(
          engine_config: EngineConfig.new({}),
          default_paths: ["**/*.js", "**/*.jsx"],
          language: "javascript",
        )

        assert_equal file_list.files, ["./foo.js", "./foo.jsx"]
      end

      it "returns files from engine config defined paths when present" do
        file_list = ::CC::Engine::Analyzers::FileList.new(
          engine_config: EngineConfig.new({
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

        assert_equal file_list.files, ["./foo.ex"]
      end

      it "returns files from default_paths when languages is an array" do
        file_list = ::CC::Engine::Analyzers::FileList.new(
          engine_config: EngineConfig.new({
            "config" => {
              "languages" => [
                "elixir"
              ],
            },
          }),
          default_paths: ["**/*.js", "**/*.jsx"],
          language: "javascript",
        )

        assert_equal file_list.files, ["./foo.js", "./foo.jsx"]
      end

      it "excludes files from paths in exclude_files" do
        file_list = ::CC::Engine::Analyzers::FileList.new(
          engine_config: EngineConfig.new({
            "exclude_paths" => ["**/*.js"],
            "config" => {
              "languages" => [
                "elixir"
              ],
            },
          }),
          default_paths: ["**/*.js", "**/*.jsx"],
          language: "javascript",
        )

        assert_equal file_list.files, ["./foo.jsx"]
      end
    end
  end
end
