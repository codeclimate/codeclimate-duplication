module CC
  module Engine
    class ParseMetrics
      def initialize(language:, io:)
        @language = language
        @io = io
        @counts = Hash.new(0)
      end

      def incr(result_type)
        counts[result_type] += 1
      end

      def report
        counts.each do |result_type, count|
          doc = metric_doc(result_type, count)
          # puts allows a race between content newline, use print
          io.print("#{JSON.generate(doc)}\0\n")
        end
      end

      private

      attr_reader :counts, :io, :language

      def metric_doc(result_type, count)
        {
          name: "#{language}.parse.#{result_type}",
          type: "measurement",
          value: count,
        }
      end
    end
  end
end
