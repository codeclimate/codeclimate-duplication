require "cc/engine/analyzers/sexp"

module CC
  module Engine
    class SexpBuilder
      def initialize(node, file)
        @node = node
        @file = file
      end

      def build
        case node
        when CC::Parser::Node then create_sexp(node.type, node.send(:properties))
        when Array then node.map { |v| self.class.new(v, file).build }
        else node.to_s.to_sym
        end
      end

      private

      attr_reader :node, :file

      def create_sexp(type, properties)
        sexps = properties.map do |key, value|
          Sexp.new(key.to_sym, *self.class.new(value, file).build).tap do |s|
            s.file = file
            if value.is_a? CC::Parser::Node
              s.line = value.location.first_line
              s.end_line = value.location.last_line
            else
              s.line = node.location.first_line
              s.end_line = node.location.last_line
            end
          end
        end

        Sexp.new(type.to_sym, *sexps).tap do |s|
          s.file = file
          s.line = node.location.first_line
          s.end_line = node.location.last_line
        end
      end
    end
  end
end
