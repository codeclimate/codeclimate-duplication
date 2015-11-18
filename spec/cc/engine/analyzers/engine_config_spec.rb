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

  describe "#paths_for" do
    it "returns paths values for given language" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "EliXiR" => {
              "paths" => ["/", "/etc"],
            }
          }
        }
      })

      expect(engine_config.paths_for("elixir")).to eq(["/", "/etc"])
    end

    it "returns nil if language is an empty key" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "EliXiR" => ""
          }
        }
      })
      expect(engine_config.paths_for("elixir")).to be_nil
    end
  end

  shared_examples "mass_threshold examples" do
    it "returns configured mass threshold as integer" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "EliXiR" => {
              specific_mass_threshold_key => "13"
            }
          }
        }
      })

      expect(engine_config.send(tested_method, "elixir")).to eq(13)
    end

    it "returns fallback mass threshold as integer" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "EliXiR" => {
              "mass_threshold" => "13"
            }
          }
        }
      })

      expect(engine_config.send(tested_method, "elixir")).to eq(13)
    end

    it "returns nil when language is empty" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "ruby" => "",
          }
        }
      })

      expect(engine_config.send(tested_method, "ruby")).to be_nil
    end
  end

  describe "similar_mass_threshold_for" do
    include_examples "mass_threshold examples" do
      let(:specific_mass_threshold_key) { "similar_mass_threshold" }
      let(:tested_method) { :similar_mass_threshold_for }
    end
  end

  describe "identical_mass_threshold_for" do
    include_examples "mass_threshold examples" do
      let(:specific_mass_threshold_key) { "identical_mass_threshold" }
      let(:tested_method) { :identical_mass_threshold_for }
    end
  end

  describe "exlude_paths" do
    it "returns given include paths" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "include_paths" => ["/tmp"]
      })

      expect(engine_config.include_paths).to eq(["/tmp"])
    end
  end
end
