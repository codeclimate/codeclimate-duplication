require 'cc/engine/analyzers/ruby/main'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'
require 'flay'
require 'tmpdir'

RSpec.describe CC::Engine::Analyzers::Ruby::Main do
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
      create_source_file("foo.rb", <<-EORUBY)
          describe '#ruby?' do
            before { subject.type = 'ruby' }

            it 'returns true' do
              expect(subject.ruby?).to be true
            end
          end

          describe '#js?' do
            before { subject.type = 'js' }

            it 'returns true' do
              expect(subject.js?).to be true
            end
          end
      EORUBY

      result = run_engine.strip
      json = JSON.parse(result)

      expect(json["type"]).to eq("issue")
      expect(json["check_name"]).to eq("Similar code")
      expect(json["description"]).to eq("Similar code found in 1 other location")
      expect(json["categories"]).to eq(["Duplication"])
      expect(json["location"]).to eq({
        "path" => "foo.rb",
        "lines" => { "begin" => 1, "end" => 5 },
      })
      expect(json["remediation_points"]).to eq(360000)
      expect(json["other_locations"]).to eq([
        {"path" => "foo.rb", "lines" => { "begin" => 9, "end" => 13} },
      ])
      expect(json["content"]["body"]).to match /This issue has a mass of `36`/
      expect(json["fingerprint"]).to eq("f21b75bbd135ec3ae6638364d5c73762")
    end

    it "skips unparsable files" do
      create_source_file("foo.rb", <<-EORUBY)
        ---
      EORUBY

      expect {
        expect(run_engine).to eq("")
      }.to output(/Skipping file/).to_stderr
    end
  end

  def create_source_file(path, content)
    File.write(File.join(@code, path), content)
  end

  def run_engine(config = {})
    io = StringIO.new

    config = CC::Engine::Analyzers::EngineConfig.new(config)
    engine = ::CC::Engine::Analyzers::Ruby::Main.new(engine_config: config)
    reporter = ::CC::Engine::Analyzers::Reporter.new(double(concurrency: 2), engine, io)

    reporter.run

    io.string
  end
end
