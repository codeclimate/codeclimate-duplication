require "spec_helper"
require "cc/engine/analyzers/python/main"
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'
require "flay"
require "tmpdir"

module CC::Engine::Analyzers::Python
  describe Main do
    before do
      @code = Dir.mktmpdir
      Dir.chdir(@code)
    end

    after do
      FileUtils.rm_rf(@code)
    end

    describe "#run" do
      it "prints an issue" do

        create_source_file("foo.py", <<-EOJS)
print("Hello", "python")
print("Hello", "python")
print("Hello", "python")
        EOJS

        assert_equal run_engine(engine_conf), printed_issue
      end

      def create_source_file(path, content)
        File.write(File.join(@code, path), content)
      end

      def run_engine(config = nil)
        io = StringIO.new

        engine = ::CC::Engine::Analyzers::Python::Main.new(engine_config: config)
        reporter = ::CC::Engine::Analyzers::Reporter.new(engine, io)

        reporter.run

        io.string
      end

      def printed_issue
        issue = {"type":"issue","check_name":"Identical code","description":"Similar code found in 2 other locations","categories":["Duplication"],"location":{"path":"foo.py","lines":{"begin":1,"end":1}},"remediation_points":81000, "other_locations":[{"path":"foo.py","lines":{"begin":2,"end":2}},{"path":"foo.py","lines":{"begin":3,"end":3}}], "content":{"body": read_up}}
        issue.to_json + "\0\n"
      end

      def engine_conf
        CC::Engine::Analyzers::EngineConfig.new({
          "config" => {
            "languages" => {
              "python" => {
                "mass_threshold" => 4
              }
            }
          }
        })
      end
    end
  end
end
