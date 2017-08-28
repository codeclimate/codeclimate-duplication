module CC
  module Engine
    class SexpBuilder
      def initialize(input, path)
        @input = input
        @path = path
      end

      def build
        if input.is_a?(CC::Parser::Node)
          sexp(input.type.to_sym, *build_properties(input))
        elsif input.is_a?(Array)
          input.map do |node|
            self.class.new(node, path).build
          end
        end
      end

      private

      attr_reader :input, :path

      def build_properties(node)
        node.properties.map do |key, property|
          if property.is_a?(CC::Parser::Node)
            sexp(key.to_sym, self.class.new(property, path).build)
          elsif property.is_a?(Array)
            sexp(key.to_sym, *self.class.new(property, path).build)
          else
            property.to_s.to_sym
          end
        end
      end

      def sexp(*args)
        Sexp.new(*args).tap do |sexp|
          sexp.file = path
          sexp.line = input.location.first_line
          sexp.end_line = input.location.last_line
        end
      end
    end
  end
end
