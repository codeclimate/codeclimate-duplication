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
        expect(json["check_name"]).to eq("Similar code")
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

        expect {
          expect(run_engine(engine_conf)).to eq("")
        }.to output(/Skipping file/).to_stderr
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
  end
end
