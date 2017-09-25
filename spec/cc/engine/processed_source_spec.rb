require "spec_helper"
require "cc/engine/processed_source"

RSpec.describe CC::Engine::ProcessedSource, in_tmpdir: true do
  include AnalyzerSpecHelpers

  describe "#ast" do
    it "returns an AST" do

      create_source_file("foo.java", <<-EOF)
        public class Carousel {
          public int fav_num = 3;
          public int least_fav_num = 0x0000000;
        }
      EOF

      path = "foo.java"
      request_path = "/java"
      processed_source = described_class.new(path, request_path)
      ast = processed_source.ast

      expect(ast).to be_a CC::Parser::Node
      expect(ast.type).to eq("CompilationUnit")
      numbers = with_type("IntegerLiteralExpr", ast)
      expect(numbers.length).to eq(2)
      expect(numbers.first.properties.fetch("value")).to eq("3")
      expect(numbers.last.properties.fetch("value")).to eq("0x0000000")
    end

    def with_type(type, node)
      flattened = flatten(node)
      flattened.select { |child| child.type == type }
    end

    def flatten(node)
      ([node] + node.properties.fetch("body").map { |child| flatten(child) }).flatten
    end
  end
end
