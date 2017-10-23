# frozen_string_literal: true

require "cc/engine/analyzers/php/visitor"

module CC
  module Engine
    module Analyzers
      module Php
        module Nodes
          class Node
            def initialize(attrs)
              @attrs = attrs
            end

            def accept(visitor)
              node_type = @attrs[:node_type]
              visit_method = :"visit_#{node_type}Node"

              if visitor.respond_to?(visit_method)
                visitor.send(visit_method, self)
              end
            end

            def line
              @attrs[:startLine]
            end

            def file
              @attrs[:file]
            end

            def identifier
              @attrs[:name] || @attrs[:value]
            end

            def to_sexp
              CC::Engine::Analyzers::Php::Visitor.new.accept(self)
            end

            def each_pair(&block)
              @attrs.each_pair(&block)
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
