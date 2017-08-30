require "spec_helper"
require "cc/engine/duplication"

RSpec.describe CC::Engine do
  around do |example|
    Dir.mktmpdir do |directory|
      @directory = directory
      example.run
    end
  end

  describe "#languages" do
    it "Warns to stderr and raises an exception when no languages are enabled" do
      original_directory = Dir.pwd
      engine = CC::Engine::Duplication.new(directory: @directory, engine_config: {}, io: StringIO.new)

      expected_output = "Config Error: Unable to run the duplication engine without any languages enabled."
      expect(CC.logger).to receive(:info).with(expected_output)
      expect { engine.run }.to raise_error(CC::Engine::Duplication::EmptyLanguagesError)

      Dir.chdir(original_directory)
    end
  end
end
