require 'cc/engine/analyzers/node'

module CC
  module Engine
    module Analyzers
      module Javascript
        class Node < CC::Engine::Analyzers::Node
          SCRUB_PROPERTIES = %w[type start end]

          private

          def format_hash
            type = @node["type"]

            if type
              create_sexp(type.to_sym, *properties_to_sexps)
            else
              create_sexp(:exp, Array(properties_to_sexps))
            end
          end

          def set_sexp_line(sexp)
            sexp.line = @node["start"] || @line
            sexp.end_line = @node["end"] || @line
          end

          def line_number
            if @node.is_a?(Hash) && @node["start"]
              @node["start"]
            end
          end
        end
      end
    end
  end
end
