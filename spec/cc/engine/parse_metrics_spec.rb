require "spec_helper"

require "cc/engine/parse_metrics"

RSpec.describe CC::Engine::ParseMetrics do
    it "sends issues to stdout" do
      stdout = StringIO.new
      metrics = CC::Engine::ParseMetrics.new(
        language: "intercal",
        io: stdout,
      )

      metrics.incr(:source_minified)
      metrics.incr(:parse_error)
      metrics.incr(:source_minified)

      metrics.report

      out_pieces = stdout.string.split("\0\n").map(&:strip)
      expect(out_pieces.count).to eq(2)

      expect(JSON.parse(out_pieces[0])).to eq({
          "name" => "intercal.parse.source_minified",
          "type" => "measurement",
          "value" => 2,
      })

      expect(JSON.parse(out_pieces[1])).to eq({
          "name" => "intercal.parse.parse_error",
          "type" => "measurement",
          "value" => 1,
      })
    end
end
