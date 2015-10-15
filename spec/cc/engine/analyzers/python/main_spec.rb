require "spec_helper"
require "cc/engine/analyzers/python/main"
require "flay"
require "tmpdir"

module CC::Engine::Analyzers::Python
  describe Main do
    before { @code = Dir.mktmpdir }

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

        engine = ::CC::Engine::Analyzers::Python::Main.new(directory: @code, engine_config: config)
        reporter = ::CC::Engine::Analyzers::Reporter.new(@code, engine, io)

        reporter.run

        io.string
      end

      def printed_issue
        issue = {"type":"issue","check_name":"Identical code","description":"Duplication found in Print","categories":["Duplication"],"location":{"path":"foo.py","lines":{"begin":1,"end":1}},"remediation_points":990000, "other_locations":[{"path":"foo.py","lines":{"begin":2,"end":2}},{"path":"foo.py","lines":{"begin":3,"end":3}}], "content":{"body": read_up}}
        issue.to_json + "\0\n"
      end

      def engine_conf
        { "config" => { "python" => { "mass_threshold" => 4 } } }
      end
    end
  end
end
