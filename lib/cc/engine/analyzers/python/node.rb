module CC
  module Engine
    module Analyzers
      module Python
        class Node
          SCRUB_PROPERTIES = ["_type", "attributes"].freeze

          def initialize(node, file, default_line = 0)
            @node = node
            @file = file

            set_default_line(default_line)
          end

          def format
            if @node.is_a?(Hash)
              type = @node["_type"].to_sym

              if valid_properties
                create_sexp(type, *properties_to_sexps)
              else
                type
              end
            elsif @node.is_a?(Array)
              @node.map do |n|
                Node.new(n, @file, @line).format
              end
            end
          end

          private

          def properties_to_sexps
            valid_properties.map do |key, value|
              if value.is_a?(Array) || value.is_a?(Hash)
                create_sexp(key.to_sym, *Node.new(value, @file, @line).format)
              else
                create_sexp(key.to_sym, value)
              end
            end
          end

          def create_sexp(*args)
            Sexp.new(*args).tap do |sexp|
              sexp.file = @file
              sexp.line = @line
            end
          end

          def valid_properties
            @node.reject do |key, value|
              value_empty = value == nil || value == {} || value == []
              SCRUB_PROPERTIES.include?(key) || value_empty
            end
          end

          def set_default_line(default)
            if has_line_number?
              @line = @node["attributes"]["lineno"]
            else
              @line = default
            end
          end

          def has_line_number?
            @node.is_a?(Hash) && @node["attributes"] && @node["attributes"]["lineno"]
          end
        end
      end
    end
  end
end
