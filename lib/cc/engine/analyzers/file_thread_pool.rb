require "thread"

module CC
  module Engine
    module Analyzers
      class FileThreadPool
        DEFAULT_CONCURRENCY = 2
        MAX_CONCURRENCY = 2

        class JumpyThread < Thread
        end

        JumpyThread.abort_on_exception = true

        def initialize(files, concurrency: DEFAULT_CONCURRENCY)
          @files = files
          @concurrency = concurrency
        end

        def run(&block)
          queue = build_queue
          lock = Mutex.new

          @workers = Array.new(thread_count) do
            JumpyThread.new do
              while (item = next_item(queue, lock))
                yield item
              end
            end
          end
        end

        def join
          workers.map(&:join)
        end

        private

        attr_reader :files, :concurrency, :workers

        def next_item(queue, lock)
          lock.synchronize { queue.pop(true) unless queue.empty? }
        end

        def build_queue
          Queue.new.tap do |queue|
            files.each do |file|
              queue.push(file)
            end
          end
        end

        def thread_count
          if (1..MAX_CONCURRENCY) === concurrency
            concurrency
          elsif concurrency < 1
            DEFAULT_CONCURRENCY
          else
            DEFAULT_CONCURRENCY
          end
        end
      end
    end
  end
end
