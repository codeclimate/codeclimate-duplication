require 'cc/engine/analyzers/javascript/nodes'

module CC
  module Engine
    module Analyzers
      module Javascript
        class AST
          def self.json_to_ast(ast, filename)
            return nil unless ast

            node_type = ast.delete("type")
            class_name = "::CC::Engine::Analyzers::Javascript::Nodes::#{node_type}Node"

            klass = Object.const_get(class_name)

            klass.new.tap do |node|
              node.file = filename

              if ast["loc"]
                node.line = ast["loc"]["start"]["line"]
                ast.delete("loc")
              end

              ast.each do |key, value|

                if value.is_a?(Array)
                  node.send("#{key}=", value.map { |v| json_to_ast(v, filename) })
                elsif value.is_a?(Hash) && value.has_key?("type")
                  node.send("#{key}=", json_to_ast(value, filename))
                elsif value.is_a?(Hash)
                  # This is happening for regexp literals (e.g. /foo/)...
                  # They are returned as {} from esprima. Converting to nil for now.
                  node.send("#{key}=", nil)
                else
                  node.send("#{key}=", value)
                end
              end
            end
          end
        end
      end
    end
  end
end
