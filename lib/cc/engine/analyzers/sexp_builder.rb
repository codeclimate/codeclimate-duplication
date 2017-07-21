require "cc/engine/analyzers/sexp"

module CC
  module Engine
    module Analyzers
      class SexpBuilder
        def initialize(node, file)
          @node = node
          @file = file
        end

        def build
          if node.is_a?(CC::Parser::Node)
            sexp(node.type.to_sym, *build_properties(node))
          elsif node.is_a?(Array)
            node.map do |value|
              self.class.new(value, file).build
            end
          end
        end

        protected

        def build_property?(key, value)
          true
        end

        private

        attr_reader :node, :file

        def build_properties(other)
          other.properties.map do |key, value|
            if build_property?(key, value)
              if value.is_a?(CC::Parser::Node) then sexp(key.to_sym, self.class.new(value, file).build)
              elsif value.is_a?(Array) then sexp(key.to_sym, *self.class.new(value, file).build)
              else value.to_s.to_sym
              end
            end
          end
        end

        def sexp(*args)
          Sexp.new(*args).tap do |sexp|
            sexp.file = file
            sexp.line = node.location.first_line
            sexp.end_line = node.location.last_line
          end
        end
      end
    end
  end
end
