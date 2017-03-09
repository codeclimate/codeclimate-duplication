require "spec_helper"
require "cc/engine/duplication"

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

        sexp = RubyParser.new.process(source, "file.rb")
        flay.process_sexp(sexp)
        report = flay.analyze[0]
        sexps = flay.hashes[report.structural_hash]
        locations = sexps.map { |sexp| SexpLines.new(sexp) }

        expect(locations.count).to eq 2
        expect(locations[0].begin_line).to eq(7) # seems like a bug in ruby_parser
        expect(locations[0].end_line).to eq(7)
        expect(locations[1].begin_line).to eq(7) # seems like a bug in ruby_parser
        expect(locations[1].end_line).to eq(7)
      end
    end
  end
end
