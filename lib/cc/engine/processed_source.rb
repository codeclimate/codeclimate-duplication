require "cc/parser"

module CC
  module Engine
    class ProcessedSource
      attr_reader :path

      def initialize(path, request_path)
        @path = path
        @request_path = request_path
      end

      def raw_source
        @raw_source ||= File.binread(path)
      end

      def ast
        @ast ||= CC::Parser.parse(raw_source, request_path)
      end

      private

      attr_reader :request_path
    end
  end
end
