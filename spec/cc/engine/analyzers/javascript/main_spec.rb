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

      result = run_engine(engine_conf).strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Identical code")
      expect(json["description"]).to eq("Similar code found in 2 other locations")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.js",
        "lines" => { "begin" => 1, "end" => 1 },
      })
      expect(json["remediation_points"]).to eq(297000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.js", "lines" => { "begin" => 2, "end" => 2} },
        {"path" => "foo.js", "lines" => { "begin" => 3, "end" => 3} }
      ])
      expect(json["content"]).to eq({ "body" => read_up })
      expect(json["fingerprint"]).to eq("55ae5d0990647ef496e9e0d315f9727d")
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

  it "does not report the same line for multiple issues" do
    create_source_file("dup.jsx", <<-EOJSX)
          <a className='button button-primary full' href='#' onClick={this.onSubmit.bind(this)}>Login</a>
    EOJSX

    result = run_engine(engine_conf).strip
    issues = result.split("\0")
    expect(issues.length).to eq 1
  end

  def create_source_file(path, content)
    File.write(File.join(@code, path), content)
  end

  def run_engine(config = nil)
    io = StringIO.new

    engine = ::CC::Engine::Analyzers::Javascript::Main.new(engine_config: config)
    reporter = ::CC::Engine::Analyzers::Reporter.new(double(concurrency: 2), engine, io)

    reporter.run

    io.string
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
