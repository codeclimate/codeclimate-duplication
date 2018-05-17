# frozen_string_literal: true

require "flay"
require "concurrent"
require "digest"

##
# A thread-safe and stable hash subclass of Flay.

class CCFlay < Flay
  def initialize(option = nil)
    super

    @hashes = Concurrent::Hash.new do |hash, key|
      hash[key] = Concurrent::Array.new
    end

    self.identical = Concurrent::Hash.new
    self.masses = Concurrent::Hash.new
  end

  def post_filter *patterns
    return if patterns.empty?

    self.hashes.delete_if { |_, sexps|
      sexps.any? { |sexp|
        patterns.any? { |pattern|
          # pattern =~ sexp
          pattern.satisfy? sexp
        }
      }
    }
  end

  def prune
    post_filter(*option[:post_filters])

    super
  end
end

class Sexp
  attr_writer :mass

  def flatter
    result = dup.clear
    result.mass = mass

    each_with_object(result) do |s, r|
      if s.is_a?(Sexp)
        ss = s.flatter

        # s(:a, s(:b, s(:c, 42))) => s(:a, :b, s(:c, 42))
        if ss.size == 2 && ss[1].is_a?(Sexp)
          r.concat ss
        else
          r << ss
        end
      else
        r << s
      end
    end
  end
end
