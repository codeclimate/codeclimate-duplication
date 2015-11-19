module AnalyzerSpecHelpers
  def create_source_file(path, content)
    File.write(File.join(@code, path), content)
  end

  def engine_config_for_language(config = {})
    {
      "config" => {
        "languages" => {
          described_class::LANGUAGE => config,
        },
      },
    }
  end

  def run_engine(config = nil)
    io = StringIO.new

    engine = described_class.new(engine_config: config)
    reporter = ::CC::Engine::Analyzers::Reporter.new(double(concurrency: 2), engine, io)

    reporter.run

    io.string
  end
end
