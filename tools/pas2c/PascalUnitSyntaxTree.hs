module PascalUnitSyntaxTree where

data PascalUnit =
    Program Identifier Implementation Phrase
    | Unit Identifier Interface Implementation (Maybe Initialize) (Maybe Finalize)
    | System [TypeVarDeclaration]
    | Redo [TypeVarDeclaration]
    deriving (Show, Read, Eq)
data Interface = Interface Uses TypesAndVars
    deriving (Show, Read, Eq)
data Implementation = Implementation Uses TypesAndVars
    deriving (Show, Read, Eq)
data Identifier = Identifier String BaseType
    deriving (Show, Read, Eq)
data TypesAndVars = TypesAndVars [TypeVarDeclaration]
    deriving (Show, Read, Eq)
data TypeVarDeclaration = TypeDeclaration Identifier TypeDecl
    | VarDeclaration Bool Bool ([Identifier], TypeDecl) (Maybe InitExpression)
    | FunctionDeclaration Identifier Bool Bool Bool TypeDecl [TypeVarDeclaration] (Maybe (TypesAndVars, Phrase))
    | OperatorDeclaration String Identifier Bool TypeDecl [TypeVarDeclaration] (Maybe (TypesAndVars, Phrase))
    deriving (Show, Read, Eq)
data TypeDecl = SimpleType Identifier
    | RangeType Range
    | Sequence [Identifier]
    | ArrayDecl (Maybe Range) TypeDecl
    | RecordType [TypeVarDeclaration] (Maybe [[TypeVarDeclaration]])
    | PointerTo TypeDecl
    | String
    | AString
    | Set TypeDecl
    | FunctionType TypeDecl [TypeVarDeclaration]
    | DeriveType InitExpression
    | VoidType
    | VarParamType TypeDecl -- this is a hack
    deriving (Show, Read, Eq)
data Range = Range Identifier
           | RangeFromTo InitExpression InitExpression
           | RangeInfinite
    deriving (Show, Read, Eq)
data Initialize = Initialize String
    deriving (Show, Read, Eq)
data Finalize = Finalize String
    deriving (Show, Read, Eq)
data Uses = Uses [Identifier]
    deriving (Show, Read, Eq)
data Phrase = ProcCall Reference [Expression]
        | IfThenElse Expression Phrase (Maybe Phrase)
        | WhileCycle Expression Phrase
        | RepeatCycle Expression [Phrase]
        | ForCycle Identifier Expression Expression Phrase Bool -- The last Boolean indicates wether it's up or down counting
        | WithBlock Reference Phrase
        | Phrases [Phrase]
        | SwitchCase Expression [([InitExpression], Phrase)] (Maybe [Phrase])
        | Assignment Reference Expression
        | BuiltInFunctionCall [Expression] Reference
        | NOP
    deriving (Show, Read, Eq)
data Expression = Expression String
    | BuiltInFunCall [Expression] Reference
    | PrefixOp String Expression
    | PostfixOp String Expression
    | BinOp String Expression Expression
    | StringLiteral String
    | PCharLiteral String
    | CharCode String
    | HexCharCode String
    | NumberLiteral String
    | FloatLiteral String
    | HexNumber String
    | Reference Reference
    | SetExpression [Identifier]
    | Null
    deriving (Show, Read, Eq)
data Reference = ArrayElement [Expression] Reference
    | FunCall [Expression] Reference
    | TypeCast Identifier Expression
    | SimpleReference Identifier
    | Dereference Reference
    | RecordField Reference Reference
    | Address Reference
    | RefExpression Expression
    deriving (Show, Read, Eq)
data InitExpression = InitBinOp String InitExpression InitExpression
    | InitPrefixOp String InitExpression
    | InitReference Identifier
    | InitArray [InitExpression]
    | InitRecord [(Identifier, InitExpression)]
    | InitFloat String
    | InitNumber String
    | InitHexNumber String
    | InitString String
    | InitPChar String
    | InitChar String
    | BuiltInFunction String [InitExpression]
    | InitSet [InitExpression]
    | InitAddress InitExpression
    | InitNull
    | InitRange Range
    | InitTypeCast Identifier InitExpression
    deriving (Show, Read, Eq)

data BaseType = BTUnknown
    | BTChar
    | BTString
    | BTAString
    | BTInt Bool -- second param indicates whether signed or not
    | BTBool
    | BTFloat
    | BTRecord String [(String, BaseType)]
    | BTArray Range BaseType BaseType
    | BTFunction Bool Bool [(Bool, BaseType)] BaseType -- in (Bool, BaseType), Bool indiciates whether var or not
    | BTPointerTo BaseType
    | BTUnresolved String
    | BTSet BaseType
    | BTEnum [String]
    | BTVoid
    | BTUnit
    | BTVarParam BaseType
    deriving (Show, Read, Eq)
