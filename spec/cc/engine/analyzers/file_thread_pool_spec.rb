require "spec_helper"
require "cc/engine/analyzers/file_thread_pool"

RSpec.describe CC::Engine::Analyzers::FileThreadPool do
  describe "#run" do
    it "uses default count of threads when concurrency is not specified" do
      allow(Thread).to receive(:new)

      pool = CC::Engine::Analyzers::FileThreadPool.new([])
      pool.run  {}

      expect(Thread).to have_received(:new).exactly(
        CC::Engine::Analyzers::FileThreadPool::DEFAULT_CONCURRENCY
      ).times
    end

    it "uses default concurrency when concurrency is over max" do
      allow(Thread).to receive(:new)

      run_pool_with_concurrency(
        CC::Engine::Analyzers::FileThreadPool::DEFAULT_CONCURRENCY + 2
      )

      expect(Thread).to have_received(:new).exactly(
        CC::Engine::Analyzers::FileThreadPool::DEFAULT_CONCURRENCY
      ).times
    end

    it "uses default concucurrency when concucurrency is under 1" do
      allow(Thread).to receive(:new)

      run_pool_with_concurrency(-2)

      expect(Thread).to have_received(:new).exactly(
        CC::Engine::Analyzers::FileThreadPool::DEFAULT_CONCURRENCY
      ).times
    end

    it "uses supplied concurrency when valid" do
      allow(Thread).to receive(:new)

      run_pool_with_concurrency(1)

      expect(Thread).to have_received(:new).exactly(1).times
    end

    it "calls block for each file" do
      pool = CC::Engine::Analyzers::FileThreadPool.new(["abc", "123", "xyz"])

      results = []
      pool.run do |f|
        results.push f.reverse
      end
      pool.join

      expect(results).to include("cba")
      expect(results).to include("321")
      expect(results).to include("zyx")
    end
  end

  def run_pool_with_concurrency(concurrency)
      pool = CC::Engine::Analyzers::FileThreadPool.new(
        [],
        concurrency: concurrency
      )
      pool.run  {}
  end
end
