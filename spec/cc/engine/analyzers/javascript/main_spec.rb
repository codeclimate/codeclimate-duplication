require 'spec_helper'
require 'cc/engine/analyzers/javascript/main'
require 'flay'
require 'tmpdir'

module CC::Engine::Analyzers::Javascript
  describe Main do
    before { @code = Dir.mktmpdir }

    describe "#run" do
      it "prints an issue" do

        create_source_file("foo.js", <<-EOJS)
          console.log("hello JS!");
          console.log("hello JS!");
          console.log("hello JS!");
        EOJS

        assert_equal run_engine(engine_conf), printed_issues
      end

      def create_source_file(path, content)
        File.write(File.join(@code, path), content)
      end

      def run_engine(config = nil)
        io = StringIO.new

        flay = ::CC::Engine::Analyzers::Javascript::Main.new(directory: @code, engine_config: config, io: io)
        flay.run

        io.string
      end

      def first_issue
        {"type":"issue","check_name":"Identical code","description":"Duplication found in expression_statement","categories":["Duplication"],"location":{"path":"#{@code}/foo.js","lines":{"begin":1,"end":1}},"remediation_points":450000, "other_locations":[{"path":"#{@code}/foo.js","lines":{"begin":2,"end":2}},{"path":"#{@code}/foo.js","lines":{"begin":3,"end":3}}], "content":{"body": read_up}}
      end

      def second_issue
        {"type":"issue","check_name":"Identical code","description":"Duplication found in expression_statement","categories":["Duplication"],"location":{"path":"#{@code}/foo.js","lines":{"begin":2,"end":2}},"remediation_points":450000, "other_locations":[{"path":"#{@code}/foo.js","lines":{"begin":1,"end":1}},{"path":"#{@code}/foo.js","lines":{"begin":3,"end":3}}], "content":{"body": read_up}}
      end

      def third_issue
        {"type":"issue","check_name":"Identical code","description":"Duplication found in expression_statement","categories":["Duplication"],"location":{"path":"#{@code}/foo.js","lines":{"begin":3,"end":3}},"remediation_points":450000,"other_locations":[{"path":"#{@code}/foo.js","lines":{"begin":1,"end":1}},{"path":"#{@code}/foo.js","lines":{"begin":2,"end":2}}], "content":{"body": read_up}}
      end

      def printed_issues
        first_issue.to_json + "\0\n" + second_issue.to_json + "\0\n" + third_issue.to_json + "\0\n"
      end

      def engine_conf
        { 'config' => { 'javascript' => { 'mass_threshold' => 4 } } }
      end
    end
  end
end
