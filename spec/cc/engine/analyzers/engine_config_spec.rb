require "spec_helper"
require "cc/engine/analyzers/engine_config"
require "cc/engine/analyzers/ruby/main"
require "sexp" # to build matchers for filtering

RSpec.describe CC::Engine::Analyzers::EngineConfig  do
  describe "#config" do
    it "normalizes language config" do
      engine_config = described_class.new({
        "config" => {
          "languages" => {
            "EliXiR" => {
              "mass_threshold" => 15,
            },
          },
        },
      })

      expect(engine_config.languages).to eq({
        "elixir" =>  { "mass_threshold" => 15 },
      })
    end

    it "transforms language arrays into empty hashes" do
      engine_config = described_class.new({
        "config" => {
          "languages" => [
            "EliXiR",
            "RubY",
          ],
        },
      })

      expect(engine_config.languages).to eq({
        "elixir" => {},
        "ruby" => {},
      })
    end

    it "enables all languages by default" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {},
      })

      expect(engine_config.languages).to eq({
        "ruby" => {},
        "java" => {},
        "javascript" => {},
        "php" => {},
        "python" => {},
      })
    end

    it "raises an exception for a completely invalid config" do
      config = {
        "config" => {
          "languages" => "potato",
        }
      }

      expect {
        described_class.new(config)
      }.to raise_error(described_class::InvalidConfigError)
    end

    it "handles an array containing a hash" do
      engine_config = described_class.new({
        "config" => {
          "languages" => [
            { "ruby" => { "mass_threshold" => 20 } },
            "python"
          ]
        }
      })

      expect(engine_config.languages).to eq({
        "ruby" => { "mass_threshold" => 20 },
        "python" => {},
      })
    end

    it "raises an exception for an array containing a bad hash" do
      config = {
        "config" => {
          "languages" => [
            { "ruby" => { "mass_threshold" => 20 }, "extra_key" => 123 },
            "python"
          ]
        }
      }

      expect {
        described_class.new(config)
      }.to raise_error(described_class::InvalidConfigError)
    end
  end

  describe "minimum_mass_threshold_for" do
    it "returns configured mass threshold as integer" do
      engine_config = described_class.new({
        "config" => {
          "languages" => {
            "EliXiR" => {
              "mass_threshold" => "13",
            },
          },
          "checks" => {
            "identical-code" => {},
            "similar-code" => {},
          },
        },
      })

      expect(engine_config.minimum_mass_threshold_for("elixir")).to eq(13)
    end

    it "returns nil when language is empty" do
      engine_config = described_class.new({
        "config" => {
          "languages" => {
            "ruby" => "",
          },
        },
      })

      expect(engine_config.minimum_mass_threshold_for("ruby")).to be_nil
    end

    it "returns nil when language is empty via array" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => %w[ruby],
        },
      })

      expect(engine_config.minimum_mass_threshold_for("ruby")).to be_nil
    end

    it "uses QM threshold when one specified" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "ruby" => { "mass_threshold" => 10 },
          },
          "checks" => {
            "identical-code" => { "config" => { "threshold" => 5 } },
            "similar-code" => {},
          },
        },
      })

      expect(engine_config.minimum_mass_threshold_for("ruby")).to eq(5)
    end

    it "uses minimum QM threshold when both specified" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "ruby" => { "mass_threshold" => 10 },
          },
          "checks" => {
            "identical-code" => { "config" => { "threshold" => 5 } },
            "similar-code" => { "config" => { "threshold" => 8 } },
          },
        },
      })

      expect(engine_config.minimum_mass_threshold_for("ruby")).to eq(5)
    end
  end

  describe "#mass_threshold_for" do
    it "gives the QM check treshold when specified" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "ruby" => { "mass_threshold" => 10 },
          },
          "checks" => {
            "identical-code" => { "config" => { "threshold" => 5 } },
            "similar-code" => {},
          },
        },
      })

      expect(engine_config.mass_threshold_for("ruby", "identical-code")).to eq(5)
    end

    it "gives the legacy language threshold when specified" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "ruby" => { "mass_threshold" => 10 },
          },
          "checks" => {
            "identical-code" => { "config" => { "threshold" => 5 } },
            "similar-code" => {},
          },
        },
      })

      expect(engine_config.mass_threshold_for("ruby", "similar-code")).to eq(10)
    end

    it "gives nil when no threshold specified" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => %w[ruby],
          "checks" => {
            "identical-code" => {},
            "similar-code" => {},
          },
        },
      })

      expect(engine_config.mass_threshold_for("ruby", "identical-code")).to be_nil
    end
  end

  describe "count_threshold_for" do
    it "returns configured count threshold as integer" do
      engine_config = described_class.new({
        "config" => {
          "languages" => {
            "EliXiR" => {
              "count_threshold" => "3",
            },
          },
        },
      })

      expect(engine_config.count_threshold_for("elixir")).to eq(3)
    end

    it "returns default value when language value is empty" do
      engine_config = described_class.new({
        "config" => {
          "count_threshold" => "4",
          "languages" => {
            "ruby" => "",
          },
        },
      })

      expect(engine_config.count_threshold_for("ruby")).to eq(4)
    end

    it "returns 2 by default" do
      engine_config = described_class.new({
        "config" => {
          "languages" => {
            "ruby" => "",
          },
        },
      })

      expect(engine_config.count_threshold_for("ruby")).to eq(2)
    end
  end

  describe "filters_for" do
    it "returns configured filter for language" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "ruby" => {
              "filters" => ["(defn [m /^test_/] _ ___)"],
            },
          },
        },
      })

      exp = [s{ s(:defn, m(/^test_/), _, ___) }]

      expect(engine_config.filters_for("ruby")).to eq(exp)
    end

    it "returns default value when language value is empty" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "languages" => {
            "ruby" => "",
          },
        },
      })

      expect(engine_config.filters_for("ruby")).to eq([])
    end
  end

  describe "include_paths" do
    it "returns given include paths" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "include_paths" => ["/tmp"],
      })

      expect(engine_config.include_paths).to eq(["/tmp"])
    end
  end

  describe "concurrency" do
    it "coerces to a number" do
      engine_config = CC::Engine::Analyzers::EngineConfig.new({
        "config" => {
          "concurrency" => "45",
        },
      })

      expect(engine_config.concurrency).to eq(45)
    end
  end

  describe "#patterns_for" do
    it "returns patterns for specified language" do
      engine_config = described_class.new({
        "config" => {
          "languages" => {
            "fancy" => {
              "patterns" => [
                "**/*.fancy"
              ],
            },
          },
        },
      })

      expect(engine_config.patterns_for("fancy", []))
        .to match_array(["**/*.fancy"])
    end

    it "returns fallback patterns for missing language" do
      engine_config = described_class.new({})

      expect(engine_config.patterns_for("fancy", ["**/*.fancy"]))
        .to match_array(["**/*.fancy"])
    end
  end

  describe "#check_enabled?" do
    it "returns false for similar-code check when disabled" do
      engine_config = stub_qm_config(similar: false)

      violation = double(check_name: "similar-code", fingerprint_check_name: "Similar code")
      expect(engine_config.check_enabled?(violation.fingerprint_check_name, violation.check_name)).to eq(false)
    end

    it "returns true for similar-code check when enabled" do
      engine_config = stub_qm_config(similar: true)

      violation = double(check_name: "similar-code", fingerprint_check_name: "Similar code")
      expect(engine_config.check_enabled?(violation.fingerprint_check_name, violation.check_name)).to eq(true)
    end

    it "respects legacy config when present" do
      engine_config = described_class.new(
        "checks" => { "Similar code" => { "enabled" => false } },
        "config" => {
          "checks" => { "identical-code" => { "enabled" => true } },
        },
      )

      violation = double(check_name: "similar-code", fingerprint_check_name: "Similar code")
      expect(engine_config.check_enabled?(violation.fingerprint_check_name, violation.check_name)).to eq(false)
    end

    it "overrides legacy config when both present" do
      engine_config = described_class.new(
        "checks" => { "Similar code" => { "enabled" => false } },
        "config" => {
          "checks" => { "similar-code" => { "enabled" => false } },
        },
      )

      violation = double(check_name: "similar-code", fingerprint_check_name: "Similar code")
      expect(engine_config.check_enabled?(violation.fingerprint_check_name, violation.check_name)).to eq(false)
    end

    it "returns true by default" do
      engine_config = described_class.new({ "config" => {} })

      violation = double(check_name: "similar-code", fingerprint_check_name: "Similar code")
      expect(engine_config.check_enabled?(violation.fingerprint_check_name, violation.check_name)).to eq(true)
    end

    it "returns false for identical-code check when disabled" do
      engine_config = stub_qm_config(identical: false)

      violation = double(check_name: "identical-code", fingerprint_check_name: "Identical code")
      expect(engine_config.check_enabled?(violation.fingerprint_check_name, violation.check_name)).to eq(false)
    end

    it "returns true for identical-code check when enabled" do
      engine_config = stub_qm_config(identical: true)

      violation = double(check_name: "identical-code", fingerprint_check_name: "Identical code")
      expect(engine_config.check_enabled?(violation.fingerprint_check_name, violation.check_name)).to eq(true)
    end

    it "returns true by default" do
      engine_config = described_class.new({ "config" => {} })

      violation = double(check_name: "identical-code", fingerprint_check_name: "Identical code")
      expect(engine_config.check_enabled?(violation.fingerprint_check_name, violation.check_name)).to eq(true)
    end
  end

  describe "#all_checks_disabled?" do
    context "qm config" do
      it "returns true if all checks are disabled" do
        engine_config = stub_qm_config(identical: false, similar: false)

        expect(engine_config.all_checks_disabled?).to eq(true)
      end

      it "returns false if only one check is disabled" do
        engine_config = stub_qm_config(identical: false, similar: true)

        expect(engine_config.all_checks_disabled?).to eq(false)
      end

      it "returns false if no checks are disabled" do
        engine_config = stub_qm_config(identical: true, similar: true)

        expect(engine_config.all_checks_disabled?).to eq(false)
      end
    end

    context "legacy config" do
      it "returns true if all checks are disabled" do
        engine_config = stub_legacy_config(identical: false, similar: false)

        expect(engine_config.all_checks_disabled?).to eq(true)
      end

      it "returns false if only one check is disabled" do
        engine_config = stub_legacy_config(identical: false, similar: true)

        expect(engine_config.all_checks_disabled?).to eq(false)
      end

      it "returns false if no checks are disabled" do
        engine_config = stub_legacy_config(identical: true, similar: true)

        expect(engine_config.all_checks_disabled?).to eq(false)
      end
    end
  end

  def stub_qm_config(similar: true, identical: true)
    described_class.new({
      "config" => {
        "checks" => {
          "similar-code" => {
            "enabled" => similar,
          },
          "identical-code" => {
            "enabled" => identical,
          },
        },
      },
    })
  end

  def stub_legacy_config(similar: true, identical: true)
    described_class.new({
      "checks" => {
        "Similar code" => {
          "enabled" => similar,
        },
        "Identical code" => {
          "enabled" => identical,
        },
      },
    })
  end
end
