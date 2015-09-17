module CC
  module Engine
    module Analyzers
      module Javascript
        class Visitor
          ALL_NODES = %w[
            ArrayExpression
            ArrayPattern
            ArrowFunctionExpression
            AssignmentExpression
            BinaryExpression
            BlockStatement
            BreakStatement
            CallExpression
            CatchClause
            ClassBody
            ClassDeclaration
            ComprehensionBlock
            ComprehensionExpression
            ConditionalExpression
            ContinueStatement
            DebuggerStatement
            DoWhileStatement
            EmptyStatement
            ExportBatchSpecifier
            ExportDeclaration
            ExportSpecifier
            ExpressionStatement
            ForInStatement
            ForOfStatement
            ForStatement
            FunctionDeclaration
            FunctionExpression
            Identifier
            IfStatement
            ImportDeclaration
            ImportSpecifier
            LabeledStatement
            Literal
            LogicalExpression
            MemberExpression
            MethodDefinition
            ModuleDeclaration
            NewExpression
            ObjectExpression
            ObjectPattern
            Program
            Property
            ReturnStatement
            SequenceExpression
            SpreadElement
            SwitchCase
            SwitchStatement
            TaggedTemplateExpression
            TemplateElement
            TemplateLiteral
            ThisExpression
            ThrowStatement
            TryStatement
            UnaryExpression
            UpdateExpression
            VariableDeclaration
            VariableDeclarator
            WhileStatement
            WithStatement
            YieldExpression
          ]

          def accept(target)
            target.accept(self)
          end

          ALL_NODES.each do |type|
            eval <<-RUBY
              def visit_#{type}Node(node)
                properties = node.class.properties
                if properties.size.zero?
                  nil
                elsif properties.size == 1
                  process_property(properties[0], node)
                else
                  properties.map do |property|
                    process_property(property, node)
                  end
                end
              end
            RUBY
          end

          def process_property(property, node)
            value = node.send(property.name)

            case property.type
            when :required
              value.accept(self)
            when :optional
              value.accept(self) if value
            when :repeated
              Array(value).map do |n|
                n.accept(self) if n
              end
            when :scalar
              value
            else
              raise "Unknown property type: #{property.type.inspect}"
            end
          end
        end

        class SexpVisitor < Visitor
          ALL_NODES.each do |type|
            eval <<-RUBY
              def visit_#{type}Node(o)
                sexp = ::CC::Engine::Analyzers::Javascript::Sexp.new(:#{type.scan(/[A-Z][a-z]+/).join('_').downcase}, *super(o))
                sexp.line = o.line
                sexp.file = o.file
                sexp
              end
            RUBY
          end
        end
      end
    end
  end
end


