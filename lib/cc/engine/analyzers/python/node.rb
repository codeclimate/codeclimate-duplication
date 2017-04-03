# frozen_string_literal: true

require "cc/engine/analyzers/node"

module CC
  module Engine
    module Analyzers
      module Python
        class Node < CC::Engine::Analyzers::Node
          SCRUB_PROPERTIES = %w[_type attributes ctx].freeze

          private

          def format_hash
            type = @node["_type"].to_sym

            if valid_properties
              create_sexp(type, *properties_to_sexps)
            else
              type
            end
          end

          def line_number
            if @node.is_a?(Hash)
              @node.fetch("attributes", {}).fetch("lineno", nil)
            end
          end
        end
      end
    end
  end
end
