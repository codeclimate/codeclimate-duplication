require "spec_helper"
require "cc/engine/duplication"

module CC::Engine::Analyzers
  RSpec.describe Violations do
    describe "#each" do
      it "yields correct number of violations" do
        issue = double(:issue, mass: 10, identical?: true)
        hashes = sexps
        language_strategy = double(:language_strategy, calculate_points: 30)

        violations = []

        Violations.new(language_strategy, issue, hashes).each do |v|
          violations << v
        end

        expect(violations.length).to eq(3)
      end

      it "yields violation objects with correct information" do
        issue = double(:issue, mass: 10, identical?: true)
        hashes = sexps
        language_strategy = double(:language_strategy, calculate_points: 30)

        violations = []

        Violations.new(language_strategy, issue, hashes).each do |v|
          violations << v
        end

        first_formatted = violations[0].format
        second_formatted = violations[1].format
        third_formatted = violations[2].format

        expect(first_formatted[:type]).to eq("issue")
        expect(first_formatted[:check_name]).to eq("Identical code")
        expect(first_formatted[:description]).to eq("Identical code found in 2 other locations (mass = 18)")
        expect(first_formatted[:categories]).to eq(["Duplication"])
        expect(first_formatted[:remediation_points]).to eq(30)
        expect(first_formatted[:location]).to eq({:path=>"file.rb", :lines=>{:begin=>1, :end=>5}})
        expect(first_formatted[:other_locations]).to eq([
          { :path => "file.rb", :lines => { :begin => 9, :end => 13} },
          { :path => "file.rb", :lines => { :begin => 17, :end => 21} },
        ])
        expect(first_formatted[:fingerprint]).to eq("f52d2f61a77c569513f8b6314a00d013")

        expect(second_formatted[:location]).to eq({:path=>"file.rb", :lines=>{:begin=>9, :end=>13}})
        expect(second_formatted[:other_locations]).to eq([
          { :path => "file.rb", :lines => { :begin => 1, :end => 5} },
          { :path => "file.rb", :lines => { :begin => 17, :end => 21} },
        ])

        expect(third_formatted[:location]).to eq({:path=>"file.rb", :lines=>{:begin=>17, :end=>21}})
        expect(third_formatted[:other_locations]).to eq([
          { :path => "file.rb", :lines => { :begin => 1, :end => 5} },
          { :path => "file.rb", :lines => { :begin => 9, :end => 13} },
        ])
      end

      def sexps
        source = <<-SOURCE
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
        SOURCE

        flay = Flay.new({
          diff: false,
          mass: CC::Engine::Analyzers::Ruby::Main::DEFAULT_MASS_THRESHOLD,
          summary: false,
          verbose: false,
          number: true,
          timeout: 10,
          liberal: false,
          fuzzy: false,
          only: nil,
        })

        sexp = RubyParser.new.process(source, "file.rb")
        flay.process_sexp(sexp)
        report = flay.analyze[0]
        sexps = flay.hashes[report.structural_hash]
      end
    end
  end
end
