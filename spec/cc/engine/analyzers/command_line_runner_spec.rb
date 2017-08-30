require "spec_helper"

module CC::Engine::Analyzers
  RSpec.describe CommandLineRunner do
    describe "#run" do
      it "runs the command on the input and yields the output" do
        runner = CommandLineRunner.new("cat; echo hi")

        output = runner.run("oh ") { |o| o }

        expect(output).to eq "oh hi\n"
      end


      it "raises on errors" do
        runner = CommandLineRunner.new("echo error output >&2; false")

        expect { runner.run("") }.to raise_error(
          ParserError, /code 1:\nerror output/
        )
      end

      it "times out commands" do
        runner = CommandLineRunner.new("sleep 3", 0.01)

        expect { runner.run("") }.to raise_error(Timeout::Error)
      end

      context "when Open3 returns a nil status" do
        it "accepts it if the output parses as JSON" do
          runner = CommandLineRunner.new("")

          allow(Open3).to receive(:capture3).and_return(["{\"type\":\"issue\"}", "", nil])

          output = runner.run("") { |o| o }
          expect(output).to eq "{\"type\":\"issue\"}"
        end

        it "raises if the output was not valid JSON" do
          runner = CommandLineRunner.new("")

          allow(Open3).to receive(:capture3).and_return(["", "error output", nil])

          expect { runner.run("") }.to raise_error(
            ParserError, /code 1:\nerror output/
          )
        end
      end
    end
  end
end
