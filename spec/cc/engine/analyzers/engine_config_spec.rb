require "spec_helper"
require "cc/engine/analyzers/engine_config"
require "cc/engine/analyzers/ruby/main"

RSpec.describe CC::Engine::Analyzers::EngineConfig  do
  describe "#config" do
    it "normalizes language config" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "EliXiR" => {
              "mass_threshold" => 15
            }
          }
        }
      })

      expect(engine_config.languages,).to eq({
        "elixir" =>  { "mass_threshold" => 15 }
      })
    end

    it "transforms language arrays into empty hashes" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => [
            "EliXiR",
            "RubY"
          ]
        }
      })

      expect(engine_config.languages).to eq({
        "elixir" =>  {},
        "ruby" => {}
      })
    end

    it "returns an empty hash if languages is invalid" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => "potato",
        }
      })

      expect(engine_config.languages).to eq({})
    end
  end

  describe "mass_threshold_for" do
    it "returns configured mass threshold as integer" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "EliXiR" => {
              "mass_threshold" => "13"
            }
          }
        }
      })

      expect(engine_config.mass_threshold_for("elixir")).to eq(13)
    end

    it "returns nil when language is empty" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "ruby" => "",
          }
        }
      })

      expect(engine_config.mass_threshold_for("ruby")).to be_nil
    end
  end

  describe "include_paths" do
    it "returns given include paths" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "include_paths" => ["/tmp"]
      })

      expect(engine_config.include_paths).to eq(["/tmp"])
    end
  end
end
