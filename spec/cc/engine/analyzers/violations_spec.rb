require "spec_helper"
require "cc/engine/duplication"

module CC::Engine::Analyzers
  RSpec.describe Violations do
    describe "#each" do
      let(:issue) { double(:issue, mass: 10, identical?: true) }
      let(:hashes) { sexps }
      let(:language_strategy) { double(:language_strategy, calculate_points: 30, calculate_severity: CC::Engine::Analyzers::Base::MINOR) }
      let(:violations) { [] }

      before do
        Violations.new(language_strategy, issue, hashes).each do |v|
          violations << v
        end
      end

      it "yields correct number of violations" do
        expect(violations.length).to eq(3)
      end

      it "yields violation objects with correct information" do
        first_formatted = violations[0].format
        second_formatted = violations[1].format
        third_formatted = violations[2].format

        expect(first_formatted[:type]).to eq("issue")
        expect(first_formatted[:check_name]).to eq("Identical code")
        expect(first_formatted[:description]).to eq("Identical blocks of code found in 3 locations. Consider refactoring.")
        expect(first_formatted[:categories]).to eq(["Duplication"])
        expect(first_formatted[:remediation_points]).to eq(30)
        expect(first_formatted[:location]).to eq({:path=>"file.rb", :lines=>{:begin=>1, :end=>7}})
        expect(first_formatted[:other_locations]).to eq([
          { :path => "file.rb", :lines => { :begin => 9, :end => 15} },
          { :path => "file.rb", :lines => { :begin => 17, :end => 23} },
        ])
        expect(first_formatted[:fingerprint]).to eq("6f2425f09caf17eb2014a20bf83b9953")
        expect(first_formatted[:severity]).to eq(CC::Engine::Analyzers::Base::MINOR)

        expect(second_formatted[:location]).to eq({:path=>"file.rb", :lines=>{:begin=>9, :end=>15}})
        expect(second_formatted[:other_locations]).to eq([
          { :path => "file.rb", :lines => { :begin => 1, :end => 7} },
          { :path => "file.rb", :lines => { :begin => 17, :end => 23} },
        ])

        expect(third_formatted[:location]).to eq({:path=>"file.rb", :lines=>{:begin=>17, :end=>23}})
        expect(third_formatted[:other_locations]).to eq([
          { :path => "file.rb", :lines => { :begin => 1, :end => 7} },
          { :path => "file.rb", :lines => { :begin => 9, :end => 15} },
        ])
      end

      def sexps
        node = CC::Parser.parse(<<-SOURCE, "/ruby")
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
        SOURCE

        flay = CCFlay.new({
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

        sexp = SexpBuilder.new(node, "file.rb").build
        flay.process_sexp(sexp)
        report = flay.analyze[0]
        sexps = flay.hashes[report.structural_hash]
      end
    end
  end
end
