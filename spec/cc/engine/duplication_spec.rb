require "spec_helper"
require "cc/engine/duplication"

module CC::Engine
  describe "#languages" do
    it "Warns to stderr and raises an exception when no languages are enabled" do
      engine = Duplication.new(directory: "/code", engine_config: {}, io: StringIO.new)

      _, stderr = capture_io do
        assert_raises(Duplication::EmptyLanguagesError) { engine.run }
      end

      stderr.must_match("Config Error: Unable to run the duplication engine without any languages enabled.")
    end
  end
end
