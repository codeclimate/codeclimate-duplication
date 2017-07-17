require "cc/engine/analyzers/sexp"

module CC
  module Engine
    class SexpBuilder
      class Transformer
        def initialize(value, file, location = nil)
          @value = value
          @file = file

          @location =
            if value.is_a?(CC::Parser::Node)
              value.location
            else
              location
            end
        end

        def transform
          case value
          when CC::Parser::Node then create_sexp(value.type && value.type.to_sym, *properties_to_sexp(value))
          when Array then value.map { |v| self.class.new(v, file, location).transform }
          else value.to_s.to_sym
          end
        end

        private

        attr_reader \
          :value,
          :file,
          :location

        def create_sexp(*args)
          Sexp.new(*args).tap do |s|
            s.file = file
            s.line = location.first_line
            s.end_line = location.last_line
          end
        end

        def properties_to_sexp(node)
          node.send(:properties).map do |key, value|
            case value
            when CC::Parser::Node
              create_sexp(key.to_sym, self.class.new(value, file).transform)
            when Array
              create_sexp(key.to_sym, *self.class.new(value, file, location).transform)
            else
              value && value.to_s.to_sym
            end
          end.compact
        end
      end

      def initialize(node, file)
        @node = node
        @file = file
      end

      def build
        Transformer.new(node, file).transform
      end

      private

      attr_reader :node, :file
    end
  end
end
