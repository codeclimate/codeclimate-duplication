require 'spec_helper'
require 'cc/engine/analyzers/php/main'
require 'flay'
require 'tmpdir'

module CC::Engine::Analyzers::Javascript
  describe Main do
    before { @code = Dir.mktmpdir }

    describe "#run" do
      it "prints an issue" do

        create_source_file("foo.php", <<-EOPHP)
          <?php
          function hello($name) {
            if (empty($name)) {
              echo "Hello World!";
            } else {
              echo "Hello $name!";
            }
          }

          function hi($name) {
            if (empty($name)) {
              echo "Hi World!";
            } else {
              echo "Hi $name!";
            }
          }
        EOPHP

        assert_equal run_engine(engine_conf), printed_issues
      end

      def create_source_file(path, content)
        File.write(File.join(@code, path), content)
      end

      def run_engine(config = nil)
        io = StringIO.new

        flay = ::CC::Engine::Analyzers::Php::Main.new(directory: @code, engine_config: config, io: io)
        flay.run

        io.string
      end

      def first_issue
        {"type":"issue","check_name":"Identical code","description":"Duplication found in function","categories":["Duplication"],"location":{"path":"#{@code}/foo.php","lines":{"begin":2,"end":2}},"remediation_points":440000,"other_locations":[{"path":"#{@code}/foo.php","lines":{"begin":10,"end":10}}],"content":{"body": read_up}}
      end

      def second_issue
        {"type":"issue","check_name":"Identical code","description":"Duplication found in function","categories":["Duplication"],"location":{"path":"#{@code}/foo.php","lines":{"begin":10,"end":10}},"remediation_points":440000,"other_locations":[{"path":"#{@code}/foo.php","lines":{"begin":2,"end":2}}],"content":{"body": read_up}}
      end

      def printed_issues
        first_issue.to_json + "\0\n" + second_issue.to_json + "\0\n"
      end

      def engine_conf
        { 'config' => { 'php' => { 'mass_threshold' => 5 } } }
      end
    end
  end
end
