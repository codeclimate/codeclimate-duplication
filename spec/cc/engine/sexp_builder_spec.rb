require "spec_helper"
require "cc/engine/sexp_builder"
require "cc/parser"

RSpec.describe(CC::Engine::SexpBuilder) do
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

    it "returns similar sexps for similar nodes" do
      node0 = CC::Parser.parse(<<-EORUBY, "/ruby")
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
      EORUBY

      node1 = CC::Parser.parse(<<-EORUBY, "/ruby")
        def self.from_foo(foo)
          if foo <= 20
            new("A")
          elsif foo <= 40
            new("E")
          elsif foo <= 80
            new("I")
          elsif foo <= 160
            new("O")
          else
            new("U")
          end
        end
      EORUBY

      sexp0 = described_class.new(node0, "foo0.rb").build
      sexp1 = described_class.new(node1, "foo1.rb").build
      expect(sexp0.deep_each.map(&:first)).to eq(sexp1.deep_each.map(&:first))
    end

    it "correctly builds sexps with conditionals" do
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
      EORUBY

      sexp = described_class.new(node, "file.rb").build

      defs, _, _, args, condition_body = *sexp
      _, if_condition = *condition_body

      expect(sexp.line).to eq(1)
      expect(sexp.end_line).to eq(13)
      expect(if_condition.line).to eq(2)
      expect(if_condition.end_line).to eq(12)
      expect([*if_condition].map {|sexp| (sexp.is_a? Symbol) ? sexp : sexp.first }).
        to eq([:if, :condition, :then, :else])
    end
  end
end
