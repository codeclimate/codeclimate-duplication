module CC
  module Engine
    module Analyzers
      module Javascript
        class SexpBuilder < ::CC::Engine::Analyzers::SexpBuilder
          protected

          PROPERTIES_BLACKLIST = %w[
            start
            end
          ]

          def build_property?(key, _value)
            !PROPERTIES_BLACKLIST.include?(key)
          end
        end
      end
    end
  end
end
