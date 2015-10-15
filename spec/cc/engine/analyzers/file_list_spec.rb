require "spec_helper"
require "cc/engine/analyzers/file_list"

module CC::Engine::Analyzers
  describe FileList do
    before do
      @tmp_dir = Dir.mktmpdir

      File.write(File.join(@tmp_dir, "foo.js"), "")
      File.write(File.join(@tmp_dir, "foo.jsx"), "")
      File.write(File.join(@tmp_dir, "foo.ex"), "")
    end

    describe "#files" do
      it "returns files from default_paths when language is missing paths" do
        file_list = ::CC::Engine::Analyzers::FileList.new(
          directory: @tmp_dir,
          engine_config: {},
          default_paths: ["**/*.js", "**/*.jsx"],
          language: "javascript",
        )

        assert_equal file_list.files, ["#{@tmp_dir}/foo.js", "#{@tmp_dir}/foo.jsx"]
      end

      it "returns files from engine config defined paths when present" do
        file_list = ::CC::Engine::Analyzers::FileList.new(
          directory: @tmp_dir,
          engine_config: {
            "config" => {
              "languages" => {
                "elixir" => {
                  "paths" => ["**/*.ex"]
                }
              }
            }
          },
          default_paths: ["**/*.js", "**/*.jsx"],
          language: "elixir",
        )

        assert_equal file_list.files, ["#{@tmp_dir}/foo.ex"]
      end

      it "returns files from default_paths when languages is an array" do
        file_list = ::CC::Engine::Analyzers::FileList.new(
          directory: @tmp_dir,
          engine_config: {
            "config" => {
              "languages" => [
                "elixir"
              ],
            },
          },
          default_paths: ["**/*.js", "**/*.jsx"],
          language: "javascript",
        )

        assert_equal file_list.files, ["#{@tmp_dir}/foo.js", "#{@tmp_dir}/foo.jsx"]
      end
    end
  end
end
