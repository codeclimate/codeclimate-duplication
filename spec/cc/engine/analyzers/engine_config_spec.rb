require "spec_helper"
require "cc/engine/analyzers/engine_config"

module CC::Engine::Analyzers
  describe EngineConfig do
    describe "#config" do
      it "normalizes language config" do
        engine_config = EngineConfig.new({
          "config" => {
            "languages" => {
              "EliXiR" => {
                "mass_threshold" => 15
              }
            }
          }
        })

        assert_equal engine_config.languages, { "elixir" =>  { "mass_threshold" => 15 } }
      end

      it "transforms language arrays into empty hashes" do
        engine_config = EngineConfig.new({
          "config" => {
            "languages" => [
              "EliXiR",
              "RubY"
            ]
          }
        })

        assert_equal engine_config.languages, { "elixir" =>  {}, "ruby" => {} }
      end

      it "returns an empty hash if languages is invalid" do
        engine_config = EngineConfig.new({
          "config" => {
            "languages" => "potato",
          }
        })

        assert_equal engine_config.languages, {}
      end
    end

    describe "#paths_for" do
      it "returns paths values for given language" do
        engine_config = EngineConfig.new({
          "config" => {
            "languages" => {
              "EliXiR" => {
                "paths" => ["/", "/etc"],
              }
            }
          }
        })

        assert_equal engine_config.paths_for("elixir"), ["/", "/etc"]
      end
    end

    describe "mass_threshold_for" do
      it "returns empty hash if language is not present" do
        engine_config = EngineConfig.new({
          "config" => {
            "languages" => {
              "EliXiR" => {
                "mass_threshold" => 13
              }
            }
          }
        })

        assert_equal engine_config.mass_threshold_for("elixir"), 13
      end
    end

    describe "exlude_paths" do
      it "returns given exclude paths" do
        engine_config = EngineConfig.new({
          "exclude_paths" => ["/tmp"]
        })

        assert_equal engine_config.exclude_paths, ["/tmp"]
      end
    end
  end
end
