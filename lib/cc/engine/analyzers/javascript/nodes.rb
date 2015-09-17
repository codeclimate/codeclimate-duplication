require 'cc/engine/analyzers/javascript/visitor'
require 'cc/engine/analyzers/javascript/sexp'

module CC
  module Engine
    module Analyzers
      module Javascript
        module Nodes
          class Node
            attr_accessor :line, :file

            Property = Struct.new(:name, :type)

            def self.properties
              @properties ||= []
            end

            def self.required(name)
              add_property(name, :required)
            end

            def self.optional(name)
              add_property(name, :optional)
            end

            def self.repeated(name)
              add_property(name, :repeated)
            end

            def self.scalar(name)
              add_property(name, :scalar)
            end

            def self.add_property(name, type)
              properties << Property.new(name, type)
              attr_accessor name
            end

            def accept(visitor)
              visitor.send(:"visit_#{self.class.name.split(/::/)[-1]}", self)
            end

            def to_sexp
              ::CC::Engine::Analyzers::Javascript::SexpVisitor.new.accept(self)
            end
          end

          class ArrayExpressionNode < Node
            repeated :elements
          end

          class AssignmentExpressionNode < Node
            scalar :operator
            required :left
            required :right
          end

          class BinaryExpressionNode < Node
            scalar :operator
            required :left
            required :right
          end

          class BlockStatementNode < Node
            repeated :body
          end

          class BreakStatementNode < Node
            optional :label
          end

          class CallExpressionNode < Node
            required :callee
            repeated :arguments
          end

          class CatchClauseNode < Node
            required :param
            optional :body
          end

          class ConditionalExpressionNode < Node
            required :test
            required :consequent
            optional :alternate
          end

          class ContinueStatementNode < Node
            optional :label
          end

          class DebuggerStatementNode < Node
          end

          class DoWhileStatementNode < Node
            required :test
            required :body
          end

          class EmptyStatementNode < Node
          end

          class ExpressionStatementNode < Node
            required :expression
          end

          class ForInStatementNode < Node
            required :left
            required :right
            required :body
            scalar :each
          end

          class ForStatementNode < Node
            optional :init
            optional :test
            optional :update
            required :body
          end

          class FunctionDeclarationNode < Node
            optional :id
            repeated :params
            repeated :defaults
            optional :rest
            required :body
            scalar :generator
            scalar :expression
          end

          class FunctionExpressionNode < Node
            optional :id
            repeated :params
            repeated :defaults
            optional :rest
            required :body
            scalar :generator
            scalar :expression
          end

          class IdentifierNode < Node
            scalar :name
          end

          class IfStatementNode < Node
            required :test
            required :consequent
            optional :alternate
          end

          class LabeledStatementNode < Node
            required :label
            required :body
          end

          class LiteralNode < Node
            scalar :value
            scalar :raw
          end

          class LogicalExpressionNode < Node
            scalar :operator
            required :left
            required :right
          end

          class MemberExpressionNode < Node
            required :object
            required :property
            scalar :computed
          end

          class NewExpressionNode < Node
            required :callee
            repeated :arguments
          end

          class ObjectExpressionNode < Node
            repeated :properties
          end

          class ProgramNode < Node
            repeated :body
          end

          class PropertyNode < Node
            required :key
            required :value
            scalar :kind
            scalar :method
            scalar :shorthand
            scalar :computed
          end

          class ReturnStatementNode < Node
            optional :argument
          end

          class SequenceExpressionNode < Node
            repeated :expressions
          end

          class SwitchCaseNode < Node
            optional :test
            repeated :consequent
          end

          class SwitchStatementNode < Node
            required :discriminant
            repeated :cases # optional
          end

          class ThisExpressionNode < Node
          end

          class ThrowStatementNode < Node
            required :argument
          end

          class TryStatementNode < Node
            required :block
            repeated :handlers
            repeated :guardedHandlers
            optional :finalizer
          end

          class UnaryExpressionNode < Node
            scalar :operator
            required :argument
            scalar :prefix
          end

          class UpdateExpressionNode < Node
            scalar :operator
            required :argument
            scalar :prefix
          end

          class VariableDeclarationNode < Node
            scalar :kind
            repeated :declarations
          end

          class VariableDeclaratorNode < Node
            required :id
            optional :init
          end

          class WhileStatementNode < Node
            required :test
            required :body
          end

          class WithStatementNode < Node
            required :object
            required :body
          end

          # ES6 (http://espadrine.github.io/New-In-A-Spec/es6/)

          class ArrayPatternNode < Node
            repeated :elements
          end

          class ArrowFunctionExpressionNode < Node
            optional :id
            repeated :params
            repeated :defaults
            optional :rest
            required :body
            scalar :generator
            scalar :expression
          end

          class ClassBodyNode < Node
            repeated :body
          end

          class ClassDeclarationNode < Node
            required :id
            optional :superClass
            required :body
          end

          class ComprehensionBlockNode < Node
            required :left
            required :right
            scalar :of
          end

          class ComprehensionExpressionNode < Node
            optional :filter
            repeated :blocks
            repeated :arguments
            required :body
          end

          class ExportBatchSpecifierNode < Node
            scalar :type
            repeated :body
          end

          class ExportDeclarationNode < Node
            repeated :declaration
            repeated :specifiers
            optional :source
          end

          class ExportSpecifierNode < Node
            required :id
            scalar :name
          end

          class ForOfStatementNode < Node
            required :left
            repeated :declarations
            required :right
            required :body
          end

          class ImportDeclarationNode < Node
            repeated :specifiers
            scalar :kind
            scalar :source
          end

          class ImportSpecifierNode < Node
            required :id
            scalar :name
          end

          class MethodDefinitionNode < Node
            required :key
            required :value
            scalar :kind
            scalar :static
          end

          class ModuleDeclarationNode < Node
            required :id
            optional :source
            repeated :body
          end

          class ObjectPatternNode < Node
            repeated :properties
          end

          class SpreadElementNode < Node
            required :argument
          end

          class TaggedTemplateExpressionNode < Node
            required :tag
            required :quasi
          end

          class TemplateElementNode < Node
            optional :value
            scalar :tail
          end

          class TemplateLiteralNode < Node
            repeated :quasis
            repeated :expressions
          end

          class YieldExpressionNode < Node
            required :argument
            scalar :delegate
          end
        end
      end
    end
  end
end
