require 'spec_helper'
require 'cc/engine/analyzers/ruby/main'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'

module CC::Engine::Analyzers
  RSpec.describe Ruby::Main, in_tmpdir: true do
    include AnalyzerSpecHelpers

    describe "#run" do
      it "handles escaped multibyte characters in regular expressions" do
        create_source_file("foo.rb", <<-EORUBY)
          class Helper
            def self.sub_degrees(str)
              str.gsub(/\\d+\\°\\s/, "")
            end
          end
        EORUBY

        pending "Potential lexing bug. Ask customer to remove escaping."
        expect {
          expect(run_engine(engine_conf)).to eq("")
        }.to output(/Skipping file/).to_stderr
      end

      it "calculates locations correctly for conditional statements" do
        create_source_file("foo.rb", <<-EORUBY)
          def self.from_level(level)
            if level >= 4
              new("A")
            elsif level >= 2
              new("E")
            elsif level >= 1
              new("I")
            elsif level >= 0
              new("O")
            else
              new("U")
            end
          end

          def self.from_remediation_amount(amount)
            if amount.nil?
              NULL_RATING
            elsif amount <= 20
              new("A")
            elsif amount <= 40
              new("E")
            elsif amount <= 80
              new("I")
            elsif amount <= 160
              new("O")
            else
              new("U")
            end
          end
        EORUBY

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["location"]).to eq({
          "path" => "foo.rb",
          "lines" => { "begin" => 2, "end" => 12 },
        })
        expect(json["other_locations"]).to eq([
          {"path" => "foo.rb", "lines" => { "begin" => 18, "end" => 28} },
        ])
      end

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

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("Similar code")
        expect(json["description"]).to eq("Similar code found in 1 other location (mass = 18)")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.rb",
          "lines" => { "begin" => 1, "end" => 5 },
        })
        expect(json["remediation_points"]).to eq(1_500_000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.rb", "lines" => { "begin" => 9, "end" => 13} },
        ])
        expect(json["content"]["body"]).to match /This issue has a mass of 18/
        expect(json["fingerprint"]).to eq("b7e46d8f5164922678e48942e26100f2")
      end

      it "creates an issue for each occurrence of the duplicated code" do
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

            describe '#whaddup?' do
              before { subject.type = 'js' }

              it 'returns true' do
                expect(subject.js?).to be true
              end
            end
        EORUBY

        issues = run_engine(engine_conf).strip.split("\0")

        expect(issues.length).to eq(3)
      end

      it "skips unparsable files" do
        create_source_file("foo.rb", <<-EORUBY)
          ---
        EORUBY

        expect {
          expect(run_engine(engine_conf)).to eq("")
        }.to output(/Skipping file/).to_stderr
      end

      it "does not see hashes as similar" do
        create_source_file("foo.rb", <<-EORUBY)
          ANIMALS = {
            bat: "Bat",
            bee: "Bee",
            cat: "Cat",
            cow: "Cow",
            dog: "Dog",
            fly: "Fly",
            human: "Human",
            lizard: "Lizard",
            owl: "Owl",
            ringworm: "Ringworm",
            salmon: "Salmon",
            whale: "Whale",
          }.freeze

          TRANSPORT = {
            airplane: "Airplane",
            bicycle: "Bicycle",
            bus: "Bus",
            car: "Car",
            escalator: "Escalator",
            helicopter: "Helicopter",
            lift: "Lift",
            motorcycle: "Motorcycle",
            rocket: "Rocket",
            scooter: "Scooter",
            skateboard: "Skateboard",
            truck: "Truck",
          }.freeze
        EORUBY

        issues = run_engine(filtered_engine_conf("(hash ___)")).strip.split("\0")

        expect(issues.length).to eq(0)
      end
    end

    describe "#calculate_points(mass)" do
      let(:analyzer) { Ruby::Main.new(engine_config: engine_conf) }
      let(:base_points) { Ruby::Main::BASE_POINTS }
      let(:points_per) { Ruby::Main::POINTS_PER_OVERAGE }
      let(:threshold) { Ruby::Main::DEFAULT_MASS_THRESHOLD }

      context "when mass exceeds threshold" do
        it "calculates mass overage points" do
          mass = threshold + 10
          overage = mass - threshold

          expected_points = base_points + overage * points_per
          points = analyzer.calculate_points(mass)

          expect(points).to eq(expected_points)
        end
      end

      context "when mass is less than threshold" do
        it "calculates mass overage points" do
          mass = threshold - 5
          overage = mass - threshold

          expected_points = base_points + overage * points_per
          points = analyzer.calculate_points(mass)

          expect(points).to eq(expected_points)
        end
      end

      context "when mass equals threshold" do
        it "calculates mass overage points" do
          mass = threshold
          overage = mass - threshold

          expected_points = base_points + overage * points_per
          points = analyzer.calculate_points(mass)

          expect(points).to eq(expected_points)
        end
      end
    end

    def engine_conf
      EngineConfig.new({})
    end

    def filtered_engine_conf *patterns
      EngineConfig.new({ "config" => {
                           "languages" => {
                             "ruby" => {
                               "filters" => patterns
                             }
                           }
                         }
                       })
    end
  end
end
