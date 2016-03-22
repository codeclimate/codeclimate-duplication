module AnalyzerSpecHelpers
  def create_source_file(path, content)
    File.write(File.join(@code, path), content)
  end

  def fixture_path(fixture_name)
    File.expand_path(File.join(File.dirname(__FILE__), "../../fixtures/#{fixture_name}"))
  end

  def run_engine(config = nil)
    io = StringIO.new

    engine = described_class.new(engine_config: config)
    reporter = ::CC::Engine::Analyzers::Reporter.new(config, engine, io)

    reporter.run

    io.string
  end
end
