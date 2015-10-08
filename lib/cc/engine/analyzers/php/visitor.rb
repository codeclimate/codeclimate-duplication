module CC
  module Engine
    module Analyzers
      module Php
        class Visitor
          ALL_NODES = %w[
            AST
            AssignOp
            Cast
            MagicConst
            Scalar
            Stmt
            TraitUseAdaptation
            Alias
            ArrayDimFetch
            ArrayItem
            Array
            Assign
            AssignRef
            BinaryOp
            BitwiseAnd
            BitwiseNot
            BitwiseOr
            BitwiseXor
            Bool
            BooleanAnd
            BooleanNot
            BooleanOr
            Break
            Case
            Catch
            ClassConst
            ClassConstFetch
            ClassMethod
            Class
            Clone
            Closure
            ClosureUse
            Concat
            ConstFetch
            Const
            Continue
            DNumber
            DeclareDeclare
            Declare
            Dir
            Do
            Double
            Echo
            ElseIf
            Else
            Empty
            Encapsed
            Equal
            ErrorSuppress
            Eval
            Exit
            File
            For
            Foreach
            FullyQualified
            FuncCall
            Function
            Global
            Goto
            Greater
            GreaterOrEqual
            HaltCompiler
            Identical
            If
            Include
            InlineHTML
            Instanceof
            Int
            Interface
            Isset
            LNumber
            Label
            Line
            List
            LogicalAnd
            LogicalOr
            LogicalXor
            Method
            MethodCall
            Minus
            Mod
            Mul
            Name
            Namespace
            New
            NotEqual
            NotIdentical
            Object
            Param
            Plus
            PostDec
            PostInc
            PreDec
            PreInc
            Precedence
            Print
            Property
            PropertyFetch
            PropertyProperty
            Relative
            Return
            ShellExec
            ShiftLeft
            ShiftRight
            Smaller
            SmallerOrEqual
            StaticCall
            StaticPropertyFetch
            StaticVar
            Static
            String
            Switch
            Ternary
            Throw
            TraitUse
            Trait
            TryCatch
            UnaryMinus
            UnaryPlus
            Unset
            UseUse
            Use
            Variable
            While
            Yield
            AssignOp_BitwiseAnd
            AssignOp_BitwiseOr
            AssignOp_BitwiseXor
            AssignOp_Concat
            AssignOp_Div
            AssignOp_Minus
            AssignOp_Mod
            AssignOp_Mul
            AssignOp_Plus
            AssignOp_ShiftLeft
            AssignOp_ShiftRight
            BinaryOp_BitwiseAnd
            BinaryOp_BitwiseOr
            BinaryOp_BitwiseXor
            BinaryOp_BooleanAnd
            BinaryOp_BooleanOr
            BinaryOp_Concat
            BinaryOp_Div
            BinaryOp_Equal
            BinaryOp_Greater
            BinaryOp_GreaterOrEqual
            BinaryOp_Identical
            BinaryOp_LogicalAnd
            BinaryOp_LogicalOr
            BinaryOp_LogicalXor
            BinaryOp_Minus
            BinaryOp_Mod
            BinaryOp_Mul
            BinaryOp_NotEqual
            BinaryOp_NotIdentical
            BinaryOp_Plus
            BinaryOp_ShiftLeft
            BinaryOp_ShiftRight
            BinaryOp_Smaller
            BinaryOp_SmallerOrEqual
            MagicConst_Class
            MagicConst_Dir
            MagicConst_File
            MagicConst_Function
            MagicConst_Line
            MagicConst_Method
            MagicConst_Namespace
            MagicConst_Trait
          ]

          def accept(target)
            target.accept(self)
          end

          ALL_NODES.each do |type|
            eval <<-RUBY
              def visit_#{type}Node(node)
                node.sub_nodes.map do |sub_node|
                  sub_node.accept(self)
                end
              end
            RUBY
          end
        end

        class SexpVisitor < Visitor
          ALL_NODES.each do |type|
            eval <<-RUBY
              def visit_#{type}Node(o)
                name = :#{type.gsub(/([a-z])([A-Z])/, '\1_\2').downcase}
                sexp = Sexp.new(name, *super(o))
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

