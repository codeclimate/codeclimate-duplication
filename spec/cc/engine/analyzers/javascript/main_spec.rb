require 'cc/engine/analyzers/javascript/main'
require 'cc/engine/analyzers/reporter'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'
require 'flay'
require 'tmpdir'

RSpec.describe CC::Engine::Analyzers::Javascript::Main do
  around do |example|
    Dir.mktmpdir do |directory|
      @code = directory

      Dir.chdir(directory) do
        example.run
      end
    end
  end

  describe "#run" do
    it "prints an issue" do

      create_source_file("foo.js", <<-EOJS)
          console.log("hello JS!");
          console.log("hello JS!");
          console.log("hello JS!");
      EOJS

      expect(run_engine(engine_conf)).to eq(printed_issue)
    end
  end

  it "does not flag duplicate comments" do
      create_source_file("foo.js", <<-EOJS)
        // A comment.
        // A comment.

        /* A comment. */
        /* A comment. */
      EOJS

      expect(run_engine(engine_conf)).to be_empty
  end

  def create_source_file(path, content)
    File.write(File.join(@code, path), content)
  end

  def run_engine(config = nil)
    io = StringIO.new

    engine = ::CC::Engine::Analyzers::Javascript::Main.new(engine_config: config)
    reporter = ::CC::Engine::Analyzers::Reporter.new(engine, io)

    reporter.run

    io.string
  end

  def printed_issue
    issue = {"type":"issue","check_name":"Identical code","description":"Similar code found in 2 other locations","categories":["Duplication"],"location":{"path":"foo.js","lines":{"begin":1,"end":1}},"remediation_points":378000, "other_locations":[{"path":"foo.js","lines":{"begin":2,"end":2}},{"path":"foo.js","lines":{"begin":3,"end":3}}], "content":{"body": read_up}}
    issue.to_json + "\0\n"
  end

  def engine_conf
    CC::Engine::Analyzers::EngineConfig.new({
      'config' => {
        'languages' => {
          'javascript' => {
            'mass_threshold' => 1
          }
        }
      }
    })
  end
end
