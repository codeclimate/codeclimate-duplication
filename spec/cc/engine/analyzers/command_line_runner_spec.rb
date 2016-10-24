require "spec_helper"
require "cc/engine/duplication"

module CC::Engine::Analyzers
  RSpec.describe CommandLineRunner do
    describe "#run" do
      it "runs the command on the input and yields the output" do
        runner = CommandLineRunner.new(["echo", "{}"])

        output = runner.run("oh ") { |o| o }

        expect(output).to eq "{}\n"
      end


      it "raises on errors" do
        runner = CommandLineRunner.new("command_that_does_not_exist")

        expect { runner.run("") }.to raise_error(
          ParserError, /did not produce valid JSON.+No such file or directory/
        )
      end

      it "times out commands" do
        runner = CommandLineRunner.new("sleep 3", 0.01)

        expect { runner.run("") }.to raise_error(Timeout::Error)
      end
    end
  end
end
