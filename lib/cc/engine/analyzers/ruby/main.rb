require "erubis"
require "flay"
require "json"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"

module CC
  module Engine
    module Analyzers
      module Ruby
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "ruby"
          DEFAULT_PATHS = [
            "**/*.erb",
            "**/*.rb",
            "**/*.rake",
            "**/Rakefile",
            "**/Gemfile",
            "**/*.gemspec"
          ]
          DEFAULT_MASS_THRESHOLD = 18
          BASE_POINTS = 1_500_000
          POINTS_PER_OVERAGE = 100_000
          TIMEOUT = 300

          def calculate_points(mass)
            BASE_POINTS + (overage(mass) * POINTS_PER_OVERAGE)
          end

          private

          def overage(mass)
            mass - mass_threshold
          end

          def process_file(file)
            if File.extname(file) == ".erb"
              process_erb file
            else
              RubyParser.new.process(File.binread(file), file, TIMEOUT)
            end
          end

          def process_erb(file)
            erb = File.binread(file)
            ruby = Erubis.new(erb).src
            RubyParser.new.process(ruby, file)
          end

          class Erubis < ::Erubis::Eruby
            BLOCK_EXPR = /\s+(do|\{)(\s*\|[^|]*\|)?\s*\Z/

            def add_expr_literal(src, code)
              if code =~ BLOCK_EXPR
                src << "@output_buffer.append= " << code
              else
                src << "@output_buffer.append=(" << code << ");"
              end
            end

            def add_expr_escaped(src, code)
              if code =~ BLOCK_EXPR
                src << "@output_buffer.safe_append= " << code
              else
                src << "@output_buffer.safe_append=(" << code << ");"
              end
            end
          end
        end
      end
    end
  end
end
