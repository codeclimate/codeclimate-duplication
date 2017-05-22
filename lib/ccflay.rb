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
end

new_nodes = [
             :And, :ArrayExpression, :ArrowFunctionExpression,
             :Assign, :AssignmentExpression, :AssignmentPattern,
             :Attribute, :BinaryExpression, :BlockStatement, :BoolOp,
             :BooleanLiteral, :Break, :BreakStatement, :Call,
             :CallExpression, :CatchClause, :ClassBody,
             :ClassDeclaration, :ClassMethod, :Compare,
             :ConditionalExpression, :Continue, :ContinueStatement,
             :Dict, :Directive, :DirectiveLiteral, :DirectiveLiteral,
             :DoWhileStatement, :EmptyStatement, :Eq, :ExceptHandler,
             :ExportDefaultDeclaration, :ExportNamedDeclaration,
             :ExportSpecifier, :Expr, :ExpressionStatement, :For,
             :ForInStatement, :ForStatement, :FunctionDeclaration,
             :FunctionDef, :FunctionExpression, :Gt, :Identifier, :If,
             :IfExp, :IfStatement, :Import, :ImportDeclaration,
             :ImportDefaultSpecifier, :ImportFrom, :ImportSpecifier,
             :Index, :LabeledStatement, :LogicalExpression, :LtE,
             :MemberExpression, :Name, :NewExpression, :NotIn,
             :NullLiteral, :Num, :NumericLiteral, :ObjectExpression,
             :ObjectMethod, :ObjectPattern, :ObjectProperty, :Or,
             :Print, :RegExpLiteral, :ReturnStatement,
             :SequenceExpression, :Slice, :Str, :StringLiteral,
             :Subscript, :Super, :SwitchCase, :SwitchStatement,
             :TaggedTemplateExpression, :TemplateElement,
             :TemplateLiteral, :ThisExpression, :ThrowStatement,
             :TryExcept, :TryStatement, :Tuple, :UnaryExpression,
             :UpdateExpression, :VariableDeclaration,
             :VariableDeclarator, :WhileStatement, :Yield, :alternate,
             :argument, :arguments, :array_dim_fetch, :assign,
             :assign_op_minus, :binary_op_bitwise_and,
             :binary_op_bitwise_or, :binary_op_concat,
             :binary_op_shift_right, :binary_op_smaller_or_equal,
             :body, :callee, :cases, :comparators, :consequent,
             :declaration, :declarations, :directives, :elements,
             :elts, :exp, :expression, :expressions, :extra,
             :finalizer, :foreach, :func_call, :function, :id, :init,
             :init, :key, :keyword, :left, :list, :lnumber, :name,
             :object, :param, :params, :properties, :property,
             :quasis, :right, :specifiers, :string, :superClass,
             :target, :test, :update, :value, :values,
             :variable
            ]

# Add known javascript and php nodes to the hash registry.
new_nodes.each do |name|
  Sexp::NODE_NAMES[name] = Sexp::NODE_NAMES.size
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
