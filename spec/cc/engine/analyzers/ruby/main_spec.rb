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
        expect(CC.logger).to receive(:info).with(/Skipping file/)
        expect(run_engine(engine_conf)).to eq("")
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
                10.times { |i| if i < 5; if i % 2 == 0; subject.increase_mass!; end; end }; expect(subject.ruby?).to be true
              end
            end

            describe '#js?' do
              before { subject.type = 'js' }

              it 'returns true' do
                10.times { |i| if i < 5; if i % 2 == 0; subject.increase_mass!; end; end }; expect(subject.js?).to be true
              end
            end
        EORUBY

        issues = run_engine(engine_conf).strip.split("\0")
        result = issues.first.strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("similar-code")
        expect(json["description"]).to eq("Similar blocks of code found in 2 locations. Consider refactoring.")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.rb",
          "lines" => { "begin" => 1, "end" => 5 },
        })
        expect(json["remediation_points"]).to eq(350_000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.rb", "lines" => { "begin" => 9, "end" => 13} },
        ])
        expect(json["content"]["body"]).to match /This issue has a mass of 35/
        expect(json["fingerprint"]).to eq("fb28e849f22fbabf946d1afdeaa84c5b")
        expect(json["severity"]).to eq(CC::Engine::Analyzers::Base::MINOR)
      end

      it "creates an issue for each occurrence of the duplicated code" do
        create_source_file("foo.rb", <<-EORUBY)
            describe '#ruby?' do
              before { subject.type = 'ruby' }

              it 'returns true' do
                10.times { |i| if i < 5; if i % 2 == 0; subject.increase_mass!; end; end }; expect(subject.ruby?).to be true
              end
            end

            describe '#js?' do
              before { subject.type = 'js' }

              it 'returns true' do
                10.times { |i| if i < 5; if i % 2 == 0; subject.increase_mass!; end; end }; expect(subject.js?).to be true
              end
            end

            describe '#whaddup?' do
              before { subject.type = 'js' }

              it 'returns true' do
                10.times { |i| if i < 5; if i % 2 == 0; subject.increase_mass!; end; end }; expect(subject.js?).to be true
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

        expect(CC.logger).to receive(:info).with(/Skipping file/)
        expect(run_engine(engine_conf)).to eq("")
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

      it "respects the per-check mass thresholds" do
        create_source_file("foo.rb", <<-EORUBY)
          def identical
            puts "identical \#{thing.bar} \#{other.fun} \#{moo ? "moo" : "cluck"}"
            puts "identical \#{thing.bar} \#{other.fun} \#{moo ? "moo" : "cluck"}"
            puts "identical \#{thing.bar} \#{other.fun} \#{moo ? "moo" : "cluck"}"
          end
          describe 'similar1' do
            before { subject.type = 'js' }
            it 'returns true' do
              expect(subject.ruby?).to be true
            end
          end
          describe 'similar2' do
            before { subject.type = 'js' }
            it 'returns true' do
              expect(subject.js?).to be true
            end
          end
        EORUBY

        config = CC::Engine::Analyzers::EngineConfig.new({
          "config" => {
            "languages" => %w[ruby],
            "checks" => {
              "identical-code" => { "config" => { "threshold" => 5 } },
              "similar-code" => { "config" => { "threshold" => 20 } },
            },
          },
        })
        output = run_engine(config).strip.split("\0").first.strip
        json = JSON.parse(output)

        expect(json["check_name"]).to eq "identical-code"
        expect(json["location"]).to eq({
          "path" => "foo.rb",
          "lines" => { "begin" => 2, "end" => 2 },
        })
      end
    end

    describe "#calculate_points" do
      let(:analyzer) { Ruby::Main.new(engine_config: engine_conf) }
      let(:base_points) { Ruby::Main::BASE_POINTS }
      let(:points_per) { Ruby::Main::POINTS_PER_OVERAGE }
      let(:threshold) { Ruby::Main::DEFAULT_MASS_THRESHOLD }

      context "when mass exceeds threshold" do
        it "calculates mass overage points" do
          mass = threshold + 10
          overage = mass - threshold
          violation = OpenStruct.new(mass: mass, check_name: "identical-code")

          expected_points = base_points + overage * points_per
          points = analyzer.calculate_points(violation)

          expect(points).to eq(expected_points)
        end
      end

      context "when mass is less than threshold" do
        it "calculates mass overage points" do
          mass = threshold - 5
          overage = mass - threshold
          violation = OpenStruct.new(mass: mass, check_name: "identical-code")

          expected_points = base_points + overage * points_per
          points = analyzer.calculate_points(violation)

          expect(points).to eq(expected_points)
        end
      end

      context "when mass equals threshold" do
        it "calculates mass overage points" do
          mass = threshold
          overage = mass - threshold
          violation = OpenStruct.new(mass: mass, check_name: "identical-code")

          expected_points = base_points + overage * points_per
          points = analyzer.calculate_points(violation)

          expect(points).to eq(expected_points)
        end
      end
    end

    describe "#calculate_severity(points)" do
      let(:analyzer) { Ruby::Main.new(engine_config: engine_conf) }
      let(:base_points) { Ruby::Main::BASE_POINTS }
      let(:points_per) { Ruby::Main::POINTS_PER_OVERAGE }
      let(:threshold) { Ruby::Main::DEFAULT_MASS_THRESHOLD }

      context "when points exceed threshold" do
        it "assigns a severity of major" do
          total_points = Base::MAJOR_SEVERITY_THRESHOLD + 1
          severity = analyzer.calculate_severity(total_points)

          expect(severity).to eq(Base::MAJOR)
        end
      end

      context "when points equal threshold" do
        it "assigns a severity of major" do
          total_points = Base::MAJOR_SEVERITY_THRESHOLD
          severity = analyzer.calculate_severity(total_points)

          expect(severity).to eq(Base::MAJOR)
        end
      end

      context "when points are below threshold" do
        it "assigns a severity of minor" do
          total_points = Base::MAJOR_SEVERITY_THRESHOLD - 10
          severity = analyzer.calculate_severity(total_points)

          expect(severity).to eq(Base::MINOR)
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
