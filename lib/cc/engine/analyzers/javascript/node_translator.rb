module CC
  module Engine
    module Analyzers
      module Javascript
        class NodeTranslator < ::CC::Engine::Analyzers::NodeTranslator
          protected

          PROPERTIES_BLACKLIST = %w[
            start
            end
          ]

          def translate_property?(key, _value)
            !PROPERTIES_BLACKLIST.include?(key)
          end
        end
      end
    end
  end
end
