# frozen_string_literal: true

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

        def run
          queue = build_queue
          lock = Mutex.new

          @workers = Array.new(thread_count) do
            with_thread_abort_on_exceptions do
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
          if (1..MAX_CONCURRENCY).cover?(concurrency)
            concurrency
          elsif concurrency < 1
            DEFAULT_CONCURRENCY
          else
            DEFAULT_CONCURRENCY
          end
        end

        def with_thread_abort_on_exceptions(&block)
          thread = Thread.new(&block)
          thread.abort_on_exception = true
          thread
        end
      end
    end
  end
end
