require "thread"

module CC
  module Engine
    module Analyzers
      class FileThreadPool
        DEFAULT_CONCURRENCY = 2
        MAX_CONCURRENCY = 2

        def initialize(files, concurrency: DEFAULT_CONCURRENCY)
          @files = files
          @concurrency = concurrency
        end

        def run(&block)
          queue = build_queue

          @workers = thread_count.times.map do
            Thread.new do
              begin 
                while item = queue.pop(true)
                  yield item
                end
              rescue ThreadError
              end
            end
          end
        end

        def join
          workers.map(&:join)
        end

        private

        attr_reader :files, :concurrency, :workers

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
