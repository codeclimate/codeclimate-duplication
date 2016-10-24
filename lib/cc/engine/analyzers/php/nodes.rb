require "cc/engine/analyzers/php/visitor"
require "ostruct"

module CC
  module Engine
    module Analyzers
      module Php
        module Nodes
          class Node < OpenStruct
            def accept(visitor)
              visit_method = :"visit_#{node_type}Node"

              if visitor.respond_to?(visit_method)
                visitor.send(visit_method, self)
              end
            end

            def line
              startLine
            end

            def to_sexp
              CC::Engine::Analyzers::Php::SexpVisitor.new.accept(self)
            end

            def sub_nodes
              [].tap do |nodes|
                each_pair do |_, value|
                  case value
                  when Hash
                    value.each do |_, v|
                      nodes << v if v.is_a?(Node)
                    end
                  when Array
                    value.each do |e|
                      nodes << e if e.is_a?(Node)
                    end
                  when Node
                    nodes << value
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
