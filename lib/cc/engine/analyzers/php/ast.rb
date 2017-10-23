# frozen_string_literal: true

require "cc/engine/analyzers/php/nodes"

module CC
  module Engine
    module Analyzers
      module Php
        class AST
          def self.json_to_ast(ast, filename)
            return nil unless ast

            if ast.is_a?(Array)
              return ast.map { |v| json_to_ast(v, filename) }
            end

            unless ast.is_a?(Hash)
              return ast
            end

            prefix_re = /^(Expr|Scalar|Stmt)_?/
            suffix_re = /_$/

            node_attrs = {
              file: filename,
            }
            if (node_type = ast.delete("nodeType"))
              node_attrs[:node_type] = node_type.
                                       sub(prefix_re, "").
                                       sub(suffix_re, "")
            end
            ast.each do |key, value|
              unless key == "nodeAttributes"
                case value
                when Hash
                  value = json_to_ast(value, filename)
                when Array
                  value = value.map { |v| json_to_ast(v, filename) }
                end

                node_attrs[key.to_sym] = value
              end
            end

            Nodes::Node.new(node_attrs)
          end
        end
      end
    end
  end
end
