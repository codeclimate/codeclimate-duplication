require "spec_helper"
require "cc/engine/analyzers/sexp_builder"
require "cc/parser"

RSpec.describe(CC::Engine::Analyzers::SexpBuilder) do
  include AnalyzerSpecHelpers

  describe "#build" do
    it "converts a node to sexp with accurate location information" do
      node = CC::Parser.parse(<<-EOPHP, "/php")
        <?php
        function hello($name) {
          if (empty($name)) {
            echo "Hello World!";
          } else {
            echo "Hello $name!";
          }
        }

        function hello($name) {
          if (empty($name)) {
            echo "Hello World!";
          } else {
            echo "Hello $name!";
          }
        }
      EOPHP

      sexp = described_class.new(node, "foo.php").build

      _, statements = *sexp
      _, _, hello_one, hello_two = *statements
      expect(statements.line).to eq(1)
      expect(statements.end_line).to eq(16)
      expect(hello_one.line).to eq(2)
      expect(hello_one.end_line).to eq(8)
      expect(hello_two.line).to eq(10)
      expect(hello_two.end_line).to eq(16)
    end

    it "returns the correct line numbers for ruby" do
      node = CC::Parser.parse(<<-EORUBY, "/ruby")
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

        def self.to_level(level)
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
      EORUBY
    end
  end
end
