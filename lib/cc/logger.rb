# frozen_string_literal: true

require "logger"

module CC
  def self.logger
    @logger ||= ::Logger.new(STDERR)
  end
end
