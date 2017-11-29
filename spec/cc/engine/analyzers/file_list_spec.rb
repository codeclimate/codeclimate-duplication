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

        File.write("/tmp/bar.js", "")
        FileUtils.ln_s("/tmp/bar.js", File.join(@tmp_dir, "bar.js"))
        Dir.mkdir("/tmp/baz")
        File.write("/tmp/baz/baz.js", "")
        FileUtils.ln_s("/tmp/baz/", File.join(@tmp_dir, "baz"))

        begin
          example.run
        ensure
          FileUtils.rm_rf(["/tmp/bar.js", "/tmp/baz"])
        end
      end
    end
  end

  describe "#files" do
    it "expands patterns for directory includes, and ignores symlinks" do
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

    it "does not emit directories even if they match the patterns" do
      file_list = ::CC::Engine::Analyzers::FileList.new(
        engine_config: CC::Engine::Analyzers::EngineConfig.new(
          "include_paths" => ["./"],
        ),
        patterns: ["**/*.js"],
      )

      Dir.mkdir("vendor.js")
      File.write(File.join(@tmp_dir, "vendor.js", "vendor.src.js"), "")

      expect(file_list.files).to include("./vendor.js/vendor.src.js")
      expect(file_list.files).not_to include("./vendor.js")
    end
  end
end
