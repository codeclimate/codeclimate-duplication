require "spec_helper"
require "ccflay"

RSpec.describe CCFlay do
  describe "#flatter" do
    it "should be isomorphic" do
      inn = s(:a, s(:b, s(:c, 42)), :d, s(:e, s(:f, s(:g, s(:h, 42))), s(:i)))
      exp = s(:a,   :b, s(:c, 42),  :d, s(:e, s(:f,   :g, s(:h, 42)),  s(:i)))

      expect(inn.flatter).to eq(exp)
    end

    it "should cache the original size" do
      inn = s(:a, s(:b, s(:c, 42)), :d, s(:e, s(:f, s(:g, s(:h, 42))), s(:i)))
      exp = s(:a,   :b, s(:c, 42),  :d, s(:e, s(:f,   :g, s(:h, 42)),  s(:i)))

      expect(inn.mass).to eq(8)
      expect(exp.mass).to eq(6)

      expect(inn.flatter.mass).to eq(8)
    end
  end

  describe Sexp::NODE_NAMES do
    describe ".default_proc" do
      it "should automatically assign incrementing values for missing nodes" do
        node1 = Sexp::NODE_NAMES["some_missing_node1"]
        node2 = Sexp::NODE_NAMES["some_missing_node2"]

        expect(node1).to be > 0
        expect(node2).to eq(node1 + 1)
      end

      context "'couldn't find node type' errors (bug #206)" do
        it "should suppress them" do
          expect { Sexp::NODE_NAMES["bug_206_node"] }.to_not output.to_stderr
        end
      end
    end
  end
end
