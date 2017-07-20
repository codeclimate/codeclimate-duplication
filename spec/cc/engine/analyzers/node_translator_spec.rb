require "spec_helper"
require "cc/engine/analyzers/node_translator"

RSpec.describe(CC::Engine::Analyzers::NodeTranslator) do
  include AnalyzerSpecHelpers

  describe "#translate" do
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

      sexp = described_class.new(node, "foo.php").translate

      _, statements = *sexp
      _, _, hello_one, hello_two = *statements
      expect(statements.line).to eq(1)
      expect(statements.end_line).to eq(16)
      expect(hello_one.line).to eq(2)
      expect(hello_one.end_line).to eq(8)
      expect(hello_two.line).to eq(10)
      expect(hello_two.end_line).to eq(16)
    end
  end
end
