require 'cc/engine/analyzers/ruby/main'
require 'cc/engine/analyzers/engine_config'
require 'cc/engine/analyzers/file_list'
require 'flay'
require 'tmpdir'

module CC::Engine::Analyzers
  RSpec.describe Ruby::Main, in_tmpdir: true do
    include AnalyzerSpecHelpers

    describe "#run" do
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

        result = run_engine(engine_conf).strip
        json = JSON.parse(result)

        expect(json["type"]).to eq("issue")
        expect(json["check_name"]).to eq("Similar code")
        expect(json["description"]).to eq("Similar code found in 1 other location")
        expect(json["categories"]).to eq(["Duplication"])
        expect(json["location"]).to eq({
          "path" => "foo.rb",
          "lines" => { "begin" => 1, "end" => 5 },
        })
        expect(json["remediation_points"]).to eq(3300000)
        expect(json["other_locations"]).to eq([
          {"path" => "foo.rb", "lines" => { "begin" => 9, "end" => 13} },
        ])
        expect(json["content"]["body"]).to match /This issue has a mass of `36`/
        expect(json["fingerprint"]).to eq("f21b75bbd135ec3ae6638364d5c73762")
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

    describe "#calculate_points(issue)" do
      let(:analyzer) { Ruby::Main.new(engine_config: engine_conf) }
      let(:base_points) { Ruby::Main::BASE_POINTS }
      let(:points_per) { Ruby::Main::POINTS_PER_OVERAGE }
      let(:threshold) { Ruby::Main::DEFAULT_MASS_THRESHOLD }

      context "when issue mass exceeds threshold" do
        it "calculates mass overage points" do
          issue = double(:issue, mass: threshold + 10)
          overage = issue.mass - threshold

          expected_points = base_points + overage * points_per
          points = analyzer.calculate_points(issue)

          expect(points).to eq(expected_points)
        end
      end

      context "when issue mass is less than threshold" do
        it "calculates mass overage points" do
          issue = double(:issue, mass: threshold - 5)
          overage = issue.mass - threshold

          expected_points = base_points + overage * points_per
          points = analyzer.calculate_points(issue)

          expect(points).to eq(expected_points)
        end
      end

      context "when issue mass equals threshold" do
        it "calculates mass overage points" do
          issue = double(:issue, mass: threshold)
          overage = issue.mass - threshold

          expected_points = base_points + overage * points_per
          points = analyzer.calculate_points(issue)

          expect(points).to eq(expected_points)
        end
      end
    end

    def engine_conf
      EngineConfig.new({})
    end
  end
end
