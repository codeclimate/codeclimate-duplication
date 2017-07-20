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
            create_sexp(node.type, valid_properties)
          when Array
            node.map do |v|
              self.class.new(
                v,
                file,
                scrub_node_properties: scrub_node_properties,
                scrub_node_types: scrub_node_types,
              ).build
            end
          else
            node.to_s.to_sym
          end
        end

        private

        attr_reader \
          :node,
          :file,
          :scrub_node_properties,
          :scrub_node_types

        def create_sexp(type, properties)
          sexps = properties.map do |key, value|
            Sexp.new(
              key.to_sym,
              *self.class.new(
                value,
                file,
                scrub_node_properties: scrub_node_properties,
                scrub_node_types: scrub_node_types,
              ).build,
            ).tap do |s|
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

          unless scrub_node_types.include?(type)
            Sexp.new(type.to_sym, *sexps).tap do |s|
              s.file = file
              s.line = node.location.first_line
              s.end_line = node.location.last_line
            end
          end
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
