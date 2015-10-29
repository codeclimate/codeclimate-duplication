require 'spec_helper'
require 'cc/engine/analyzers/php/main'
require 'cc/engine/analyzers/reporter'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'
require 'flay'
require 'tmpdir'

module CC::Engine::Analyzers::Php
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

        assert_equal run_engine(engine_conf), printed_issue
      end

      def create_source_file(path, content)
        File.write(File.join(@code, path), content)
      end

      def run_engine(config = nil)
        io = StringIO.new

        engine = ::CC::Engine::Analyzers::Php::Main.new(engine_config: config)
        reporter = ::CC::Engine::Analyzers::Reporter.new(engine, io)

        reporter.run

        io.string
      end

      def printed_issue
        issue = {"type":"issue","check_name":"Identical code","description":"Similar code found in 1 other location","categories":["Duplication"],"location":{"path":"foo.php","lines":{"begin":2,"end":6}},"remediation_points":176000,"other_locations":[{"path":"foo.php","lines":{"begin":10,"end":14}}],"content":{"body": read_up}}
        issue.to_json + "\0\n"
      end

      def engine_conf
        CC::Engine::Analyzers::EngineConfig.new({
          'config' => {
            'languages' => {
              'php' => {
                'mass_threshold' => 5
              }
            }
          }
        })
      end
    end
  end
end
