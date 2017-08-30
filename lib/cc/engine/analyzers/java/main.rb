# frozen_string_literal: true

require "flay"
require "json"
require "cc/engine/analyzers/reporter"
require "cc/engine/analyzers/analyzer_base"
require "cc/engine/processed_source"
require "cc/engine/sexp_builder"

module CC
  module Engine
    module Analyzers
      module Java
        class Main < CC::Engine::Analyzers::Base
          LANGUAGE = "java".freeze
          PATTERNS = ["**/*.java"].freeze
          DEFAULT_MASS_THRESHOLD = 40
          POINTS_PER_OVERAGE = 10_000
          REQUEST_PATH = "/java".freeze
          TIMEOUT = 300

          private

          def process_file(file)
            processed_source = ProcessedSource.new(file, REQUEST_PATH)

            SexpBuilder.new(processed_source.ast, file).build
          rescue => ex
            if unparsable_file_error?(ex)
              CC.logger.warn("Skipping #{processed_source.path} due to #{ex.class}")
              CC.logger.warn("Response status: #{ex.response_status}")
              CC.logger.debug { "Contents:\n#{processed_source.raw_source}" }
              CC.logger.debug { "Response:\n#{ex.response_body}" }
              nil
            elsif ex.is_a?(CC::Parser::Client::NestingDepthError)
              CC.logger.warn("Skipping #{processed_source.path} due to #{ex.class}")
              CC.logger.warn(ex.message)
              CC.logger.debug { "Contents:\n#{processed_source.raw_source}" }
              nil
            else
              CC.logger.error("Error processing file: #{processed_source.path}")
              CC.logger.error(ex.message)
              CC.logger.debug { "Contents:\n#{processed_source.raw_source}" }
              raise
            end
          end

          def unparsable_file_error?(ex)
            ex.is_a?(CC::Parser::Client::HTTPError) &&
              ex.response_status.to_s.start_with?("4")
          end
        end
      end
    end
  end
end
