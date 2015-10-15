module CC
  module Engine
    module Analyzers
      class Node
        SCRUB_PROPERTIES = []

        def initialize(node, file, default_line = 0)
          @node = node
          @file = file

          set_default_line(default_line)
        end

        def format
          if @node.is_a?(Hash)
            format_hash
          elsif @node.is_a?(Array)
            @node.map do |n|
              self.class.new(n, @file, @line).format
            end
          end
        end

        private

        def format_hash
          raise "Subclass must implement format_hash"
        end

        def create_sexp(*args)
          Sexp.new(*args).tap do |sexp|
            sexp.file = @file
            set_sexp_line(sexp)
          end
        end

        def set_sexp_line(sexp)
          sexp.line = @line
        end

        def properties_to_sexps
          valid_properties.map do |key, value|
            if value.is_a?(Array)
              create_sexp(key.to_sym, *self.class.new(value, @file, @line).format)
            elsif  value.is_a?(Hash)
              create_sexp(key.to_sym, self.class.new(value, @file, @line).format)
            else
              create_sexp(key.to_sym, value)
            end
          end
        end

        def valid_properties
          @node.reject do |key, value|
            value_empty = [nil, {}, []].include?(value)
            self.class::SCRUB_PROPERTIES.include?(key) || value_empty
          end
        end

        def set_default_line(default)
          @line = line_number || default
        end

        def line_number
          raise "Subclass must implement `line_number`"
        end
      end
    end
  end
end
