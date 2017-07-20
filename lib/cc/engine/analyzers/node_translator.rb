module CC
  module Engine
    module Analyzers
      class NodeTranslator
        def initialize(node, file)
          @node = node
          @file = file
        end

        def translate
          case node
          when CC::Parser::Node
            sexp(node.type.to_sym, *translate_properties(node))
          when Array
            node.map do |value|
              self.class.new(value, file).translate
            end
          end
        end

        protected

        def translate_property?(key, value)
          true
        end

        private

        attr_reader :node, :file

        def translate_properties(other)
          other.properties.map do |key, value|
            if translate_property?(key, value)
              case value
              when CC::Parser::Node then self.class.new(value, file).translate
              when Array then sexp(key.to_sym, *self.class.new(value, file).translate.compact)
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
