RSpec.describe CC::Engine::Analyzers::Violation, in_tmpdir: true do
  include AnalyzerSpecHelpers

  describe "#calculate_points" do
    context "when issue mass exceeds threshold" do
      it "calculates mass overage points" do
        language = double(:language, base_points: 100, points_per_overage: 5, mass_threshold: 10)
        issue = double(:issue, mass: 15)
        hashes = []

        expected_points = 100 + 5 * (issue.mass - 10)

        violation = CC::Engine::Analyzers::Violation.new(language, issue, hashes)
        points = violation.calculate_points

        expect(points).to eq(expected_points)
      end
    end

    context "when issue mass is less than threshold" do
      it "uses default" do
        language = double(:language, base_points: 100, points_per_overage: 5, mass_threshold: 18)
        issue = double(:issue, mass: 15)
        hashes = []

        expected_points = CC::Engine::Analyzers::Violation::DEFAULT_POINTS

        violation = CC::Engine::Analyzers::Violation.new(language, issue, hashes)
        points = violation.calculate_points

        expect(points).to eq(CC::Engine::Analyzers::Violation::DEFAULT_POINTS)
      end
    end

    context "when issue mass equals threshold" do
      it "calculates remediation points" do
        language = double(:language, base_points: 100, points_per_overage: 5, mass_threshold: 18)
        issue = double(:issue, mass: language.mass_threshold)
        hashes = []

        expected_points = 100 + 5 * (issue.mass - language.mass_threshold)

        violation = CC::Engine::Analyzers::Violation.new(language, issue, hashes)
        points = violation.calculate_points

        expect(points).to eq(expected_points)
      end
    end
  end
end
