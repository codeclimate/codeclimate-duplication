require "cc/engine/analyzers/sexp"

module CC
  module Engine
    module Analyzers
      class SexpBuilder
        def initialize(node, file, scrub_node_properties: [], scrub_node_types: [])
          @node = node
          @file = file
          @scrub_node_properties = scrub_node_properties
          @scrub_node_types = scrub_node_types
        end

        def build
          case node
          when CC::Parser::Node
            create_sexp(node.type.to_sym, *properties_to_sexps)
          when Array
            node.map do |value|
              build_value(value)
            end
          end
        end

        private

        attr_reader \
          :node,
          :file,
          :scrub_node_properties,
          :scrub_node_types

        def properties_to_sexps
          valid_properties.map do |key, value|
            case value
            when Array then create_sexp(key.to_sym, *build_value(value))
            when CC::Parser::Node then create_sexp(key.to_sym, build_value(value))
            else value.to_s.to_sym
            end
          end
        end

        def create_sexp(*args)
          Sexp.new(*args).tap do |sexp|
            sexp.file = file
            sexp.line = node.location.first_line
            sexp.end_line = node.location.last_line
          end
        end

        def build_value(value)
          self.class.new(
            value,
            file,
            scrub_node_properties: scrub_node_properties,
            scrub_node_types: scrub_node_types,
          ).build
        end

        def valid_properties
          node.properties.reject do |key, value|
            value.nil? ||
              scrub_node_properties.include?(key) ||
              (value.is_a?(CC::Parser::Node) && scrub_node_types.include?(value.type))
          end
        end
      end
    end
  end
end
