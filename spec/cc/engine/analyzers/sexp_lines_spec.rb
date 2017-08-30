require "spec_helper"

module CC::Engine::Analyzers
  RSpec.describe SexpLines do
    describe "violation location" do
      it "gets appropriate locations for rescue blocks" do
        source = <<-SOURCE
          begin
            foo
          rescue SyntaxError => e
            Jekyll.logger.warn "YAML Exception reading \#{File.join(base, name)}: \#{e.message}"
          rescue Exception => e
            Jekyll.logger.warn "Error reading file \#{File.join(base, name)}: \#{e.message}"
          end
        SOURCE

        locations = locations_from_source(source)

        expect(locations.count).to eq 2
        expect(locations[0].begin_line).to eq(3)
        expect(locations[0].end_line).to eq(7)
        expect(locations[1].begin_line).to eq(5)
        expect(locations[1].end_line).to eq(7)
      end

      it "gets appropriate locations for hashes" do
        source = <<-SOURCE
          {
            name: "Bear Vs. Shark",
            greatest: true,
            city: "Ferndale",
            state: "Michigan",
            email: "shark@bear.com",
            phone: "9145551234",
          }

          {
            name: "Bars of Gold",
            greatest: true,
            city: "Ferndale",
            state: "Michigan",
            email: "barsofgold@gmail.com",
            phone: "9145551234",
          }
        SOURCE

        locations = locations_from_source(source, mass: 1)

        expect(locations.count).to eq 2

        expect([locations[0].begin_line, locations[0].end_line]).to eq([1, 7])
        expect([locations[1].begin_line, locations[1].end_line]).to eq([10, 16])
      end
    end

    def locations_from_source(source, flay_opts = {})
      flay = CCFlay.new({
        diff: false,
        mass: 18,
        summary: false,
        verbose: false,
        number: true,
        timeout: 10,
        liberal: false,
        fuzzy: false,
        only: nil,
      }.merge(flay_opts))

      sexp = RubyParser.new.process(source, "file.rb")
      flay.process_sexp(sexp)
      report = flay.analyze[0] or raise "No analysis"
      sexps = flay.hashes[report.structural_hash]
      sexps.map { |sexp| SexpLines.new(sexp) }
    end
  end
end
