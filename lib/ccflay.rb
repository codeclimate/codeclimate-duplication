require "flay"
require "concurrent"
require "digest"

##
# A thread-safe and stable hash subclass of Flay.

class CCFlay < Flay
  def initialize option = nil
    super

    @hashes = Concurrent::Hash.new do |hash, key|
      hash[key] = Concurrent::Array.new
    end

    self.identical      = Concurrent::Hash.new
    self.masses         = Concurrent::Hash.new
  end

  ##
  # Calculate the structural hash for this sexp. Cached, so don't
  # modify the sexp afterwards and expect it to be correct.

  if ENV["PURE_HASH"]
    def structural_hash
      @structural_hash ||= pure_ruby_hash
    end
    $stderr.puts "NOTE: Using pure ruby hash!"
  else
    def structural_hash
      @structural_hash ||= Digest::MD5.hexdigest(self.structure.to_s)
    end
    $stderr.puts "NOTE: Using MD5 hash!"
  end
end

# TODO: move this to flay proper... it's benchmarking faster
class Sexp # straight from flay-persistent
  names = %w(alias and arglist args array attrasgn attrset back_ref
           begin block block_pass break call case cdecl class colon2
           colon3 const cvar cvasgn cvdecl defined defn defs dot2
           dot3 dregx dregx_once dstr dsym dxstr ensure evstr false
           flip2 flip3 for gasgn gvar hash iasgn if iter ivar lasgn
           lit lvar masgn match match2 match3 module next nil not
           nth_ref op_asgn op_asgn1 op_asgn2 op_asgn_and op_asgn_or or
           postexe redo resbody rescue retry return sclass self
           splat str super svalue to_ary true undef until valias
           when while xstr yield zsuper kwarg kwsplat safe_call)

  ##
  # All ruby_parser nodes in an index hash. Used by jenkins algorithm.

  NODE_NAMES = Hash[names.each_with_index.map {|n, i| [n.to_sym, i] }]

  NODE_NAMES.default_proc = lambda { |h,k|
    $stderr.puts "ERROR: couldn't find node type #{k} in Sexp::NODE_NAMES."
    h[k] = NODE_NAMES.size
  }

  MAX_INT32 = 2 ** 32 - 1 # :nodoc:

  def pure_ruby_hash # :nodoc: see above
    hash = 0

    n = NODE_NAMES.fetch first

    raise "Bad lookup: #{first} in #{sexp.inspect}" unless n

    hash += n          & MAX_INT32
    hash += hash << 10 & MAX_INT32
    hash ^= hash >>  6 & MAX_INT32

    each do |o|
      next unless Sexp === o
      hash = hash + o.pure_ruby_hash  & MAX_INT32
      hash = (hash + (hash << 10)) & MAX_INT32
      hash = (hash ^ (hash >>  6)) & MAX_INT32
    end

    hash = (hash + (hash <<  3)) & MAX_INT32
    hash = (hash ^ (hash >> 11)) & MAX_INT32
    hash = (hash + (hash << 15)) & MAX_INT32

    hash
  end
end
