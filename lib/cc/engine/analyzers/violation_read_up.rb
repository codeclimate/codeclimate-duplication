require "erb"

module CC
  module Engine
    module Analyzers
      class ViolationReadUp
        def initialize(mass)
          @mass = mass
        end

        def contents
          ERB.new(File.read(template_path)).result(binding)
        end

        private

        attr_reader :mass

        TEMPLATE_REL_PATH = "../../../../config/contents/duplicated_code.md.erb"

        def template_path
          File.expand_path(
            File.join(File.dirname(__FILE__), TEMPLATE_REL_PATH)
          )
        end
      end
    end
  end
end
