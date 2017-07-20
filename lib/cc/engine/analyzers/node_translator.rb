module CC
  module Engine
    module Analyzers
      class NodeTranslator
        def initialize(node, file)
          @node = node
          @file = file
        end

        def translate
          translate_value(node)
        end

        protected

        def translate_property?(key, value)
          true
        end

        private

        attr_reader :node, :file

        def translate_value(value)
          case value
          when CC::Parser::Node
            sexp(value.type.to_sym, *properties(value))
          when Array
            value.map do |val|
              self.class.new(val, file).translate
            end
          end
        end

        def properties(other)
          other.properties.map do |key, value|
            if translate_property?(key, value)
              case value
              when CC::Parser::Node then translate_value(value)
              when Array then sexp(key.to_sym, *translate_value(value).compact)
              else value.to_s.to_sym
              end
            end
          end.compact
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
