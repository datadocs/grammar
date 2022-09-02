parser grammar DatadocsParser;
options { tokenVocab = DatadocsLexer;}

/*

1. GENERAL
------------------------------------------------------------------

For testing we will allow parsing multiple statements, separated by a semi-colon.

In the actual parser, we will parse one statement at a time and use a 'Splitter', such
as the one here (currently used in MySQL workbench): https://bit.ly/3ch8i5J.
This is because a user may have a long SQL script (perhaps 1M insert statements)
and we don't want to parse every statement on each character-change.

*/
testRoot
    : sqlStatement? (Semi sqlStatement)* Semi? EOF
    ;

root
    : sqlStatement (Semi EOF? | EOF)
    ;

sqlStatement
    : selectStatement
    // other Statements
    ;

/*
2. SELECT STATEMENT
------------------------------------------------------------------
This section will include the high level syntax of the SELECT statement.
Expressions, data types, and various other general components will
appear in a separate section.

A few high-level notes:

2.1. A FROM clause is not required. However, it is required for specifying WHERE/GROUP/HAVING/QUALIFY/WINDOW.
2.2. We will not support having an expression in the LIMIT or OFFSET clause (DuckDB does, BQ does not).
2.3 GROUP BY is not required for a HAVING clause, for example SELECT COUNT(1) FROM tbl HAVING COUNT(1) > 10
2.4. A column identifier may be of the form [server.][database.][schema.][field], so a four-part path at the maximum.
     Note that a field can continue down the path if it is a STRUCT.
2.5 GROUP BY clause will support standard GROUP BY and ROLLUP, but not CUBE or GROUPING SETS.
2.6 LIMIT/OFFSET may be expressed as either LIMIT 100, OFFSET 10 or LIMIT 100, 10.
2.7 Note that selectStar expression may not use an Alias. This will need to be checked in semantic validation.
2.8 We will often allow trailing commas for conevenience, such as in an SELECT or GROUP BY item list.

## Most important of all, type-checking will, for the most part, not be performed within the grammar itself.
   This is primarily noticeable in how most clauses may refer to the same `expr` rule.
   Semantically, we will need to check to make sure that the `expr` is an appropriate type for the clause.
   As a basic example, `SELECT <expr> FROM <tbl> WHERE <expr>` will need to check that the `whereExpr`
   is a boolean expression, such as `WHERE salary > 100`, and not something like `WHERE CONCAT(x, y)`.
*/
selectStatement
    : simpleSelect                                                                  # simpleQuery
    | selectStatement setOperator selectStatement                                   # setQuery
    ;

simpleSelect
    : withClause?
    ( select | OpenParen selectStatement CloseParen | valuesClause)
      orderByClause?
    ( limitClause offsetClause?)?
    ;

select:
    selectClause
    (fromClause
      whereClause?
      groupByClause?
      havingClause?
      qualifyClause?
      windowClause?
     )?;

selectClause
    : SELECT distinctModifier? selectItemList Comma?
    ;

distinctModifier
    : ALL
    | DISTINCT (ON OpenParen expr (Comma expr)* CloseParen)?
    ;

selectItemList
    : selectItem (Comma selectItem)*
    ;

selectItem
    : expr alias?                                                                   # selectOne
    | Star starExcept? starReplace?                                                 # selectStar
    ;

fromClause
    : FROM tableExpression Comma?
    ;

tableExpression
    : tableItem tableAlias? tableSample?                                            # singleTable
    | tableExpression (Comma | CROSS JOIN) tableExpression                          # crossJoinedTable
    | tableExpression (INNER? JOIN | (FULL|LEFT|RIGHT) OUTER? JOIN) tableExpression
           (ON expr | USING OpenParen identifier (Comma identifier)* CloseParen)    # conditionallyJoinedTable
    ;

tableItem
    : identifier (Dot (identifier|reservedKeyword))*                                # simplePath
    | OpenParen selectStatement CloseParen                                          # subSelect
    | ((RANGE|GLOB|UNNEST|identifier (Dot (identifier|reservedKeyword))*)
                          OpenParen functionParams? CloseParen)                     # tableFunction
    | OpenParen  valuesClause CloseParen                                            # valuesTable
    ;

valuesClause:
    VALUES OpenParen (expr (Comma expr)* Comma?) CloseParen
           (Comma OpenParen (expr (Comma expr)* Comma?) CloseParen)* Comma?
    ;

tableSample:
    TABLESAMPLE ( Integer_Literal ROWS
               | (Integer_Literal | Float_Literal) (PERCENT | Percent))
    ;

alias
    : AS? (identifier | reservedKeyword)
    ;

tableAlias
    : AS? (identifier | reservedKeyword)
          (OpenParen identifier (Comma identifier)* CloseParen)?
    ;

whereClause
    : WHERE expr
    ;

groupByClause
    : GROUP BY groupByItemList Comma?
    ;

groupByItemList
    : groupByItem (Comma groupByItem)*
    ;

groupByItem
    : expr                                                                          # simpleGroupBy
    | ROLLUP OpenParen expr (Comma expr)* CloseParen                                # rollupGroupBy
    ;

havingClause
    : HAVING expr
    ;

qualifyClause
    : QUALIFY expr
    ;

orderByClause:
    ORDER BY orderItemList Comma?
    ;

orderItemList
    : orderItem (Comma orderItem)*
    ;

orderItem
    : expr (ASC|DESC)? (NULLS (FIRST|LAST))?
    ;

limitClause
    : LIMIT (Integer_Literal | (Integer_Literal | Float_Literal) (PERCENT | Percent))
    ;

offsetClause
    : (Comma | OFFSET) Integer_Literal
    ;

withClause:
    WITH RECURSIVE? withItem (Comma withItem)*
    ;

withItem:
    identifier (OpenParen identifier (Comma identifier)* CloseParen)?
               AS OpenParen selectStatement CloseParen
    ;

windowClause:
    WINDOW windowItemList
    ;

windowItemList
    : identifier AS windowItem (Comma identifier AS windowItem)*
    ;

windowItem
    : OpenParen identifier? partitionByClause? orderByClause? windowFrame? CloseParen
    | (identifier|OpenParen identifier CloseParen)
    ;

windowFrame
    : (RANGE|ROWS) ((UNBOUNDED|expr) PRECEDING
                 | CURRENT ROW
                 | BETWEEN ((UNBOUNDED|expr) PRECEDING|CURRENT ROW|expr FOLLOWING)
                   AND ((UNBOUNDED|expr) FOLLOWING|CURRENT ROW|expr PRECEDING))
    ;

setOperator
    : UNION (DISTINCT|ALL)?
    | INTERSECT DISTINCT?
    | EXCEPT DISTINCT?
    ;

partitionByClause:
    PARTITION BY genericExpressionList
    ;

genericExpressionList
    : genericExpressionItem (Comma genericExpressionItem)*
    ;

genericExpressionItem
    : expr
    ;

namedExpressionList
    : namedExpressionItem (Comma namedExpressionItem)*
    ;

namedExpressionItem
    : (identifier | reservedKeyword) NamedParam expr
    ;

kvPairList
    : kvPairItem (Comma kvPairItem)* Comma?
    ;

kvPairItem
    : (identifier|String_Literal|reservedKeyword) Colon expr
    ;

functionParams
    : (genericExpressionList (Comma namedExpressionList)? | namedExpressionList )
    ;
/*
3. EXPRESSIONS
------------------------------------------------------------------
With few exceptions, almost all expressions are recursively defined, and so
type-checking will occur downstream as mentioned in the SELECT notes.

The following are some general notes:

3.1. A tuple or anonymous Struct is a parenExpr with at least one (potentially trailing) comma.
     In other words, a parenExpr with one or more commas is converted to an anonymous Struct.
     An example would be: (x) would be a parenExpression but (x,) or (x,1) would be a tuple.
3.2 Expressions are grouped with the following label prefixes:
    (a) arithmetic
    (b) logical
    (c) bitwise
    (d) functionCall
    (e) access
    (e) [all other expressions]
3.3 IN (subSelect) is rewritten to `= ANY(subSelect)`. This is to make types consistent with IN <struct> and IN (<subQuery>).
3.4 Note that the selectStar expression is included here, as we allow (literal).*,
    for example to display all the fields of a STRUCT in the selectList.
3.5 Path expression can get quite complex. Here are some examples with notes:
    (a) Function calls: tbl.my.function.call(), x(), x(*), x.y(a=b).z.y[0][1]
        - Always preceeded by a dotted path expression, though may be succeeded
          by additional index or dot accesses.
     (b) Array access: [1,2,3][0], {'x': [1,2,3]}.x[1], tbl.x[0][1].d[0:1][-1]
         - May be preceeded or succeeded by additional array or path accesses.
     (c) Field access: {'x': 1}.x, name().h, {'x': {'x':[1]}}.x.x[0]
        - Similar to array access may be preceeded by suceeded by array or path access.

*/

expr
    // Parenthetical expressions
    : OpenParen expr (Comma expr)* Comma? CloseParen                                # parenExpr
    | OpenParen selectStatement CloseParen                                          # subSelectExpr

    // Function -- cannot really tell which is an aggregation function
    // and which is not so we group into the same expression (esp with UDFs)
    | identifier (Dot identifier)* OpenParen
        (ALL|DISTINCT)? functionParams? orderByClause? ((RESPECT|IGNORE) NULLS)?
        CloseParen filterClause? (OVER windowItem)?                                 # functionCallExpr

    // Various anchored/unambiguous expressions
    | identifier OpenParen (DISTINCT|ALL)? Star CloseParen filterClause?
                                                    (OVER windowItem)?              # functionStarExpr
    | EXTRACT OpenParen extendedTimeUnit FROM expr CloseParen                       # extractExpr
    | (TRY_CAST|CAST) OpenParen expr AS literalType CloseParen                      # castFunctionExpr
    | POSITION OpenParen expr IN expr CloseParen                                    # positionExpr
    | (RANGE|GROUPING|IF|UNNEST|GLOB|CONTAINS|LEFT|RIGHT)
            OpenParen expr (Comma expr)* CloseParen                                 # otheReservedExpr
    | EXISTS OpenParen simpleSelect CloseParen                                      # logicalExistsExpr

    // Collate and Cast expressions
    | expr TypeCast literalType                                                     # castOperatorExpr
    | expr COLLATE (WITH|WITHOUT) CASE                                              # collateExpr

    // Path access expressions
    | expr Dot Star starExcept? starReplace?                                        # pathAccessStarExpr
    | expr (OpenBracket expr? (Colon expr?)? CloseBracket )                         # pathAccessArrayExpr
    | expr Dot (identifier|reservedKeyword)                                         # pathAccessFieldExpr

    // Arithmetic expressions
    | (Plus | Minus) expr                                                           # arithmeticUnaryPlusMinusExpr
    | BitwiseNot expr                                                               # bitwiseNotExpr
    | expr (Star | Slash | Percent) expr                                            # arithmeticTimesDivRemainderExpr
    | expr (Plus | Minus) expr                                                      # arithmeticPlusMinusExpr

    // Bitwise expressions (bitwiseNot above)
    | expr (BitShiftLeft | BitShiftRight) expr                                      # bitwiseShiftExpr
    | expr BitwiseAnd expr                                                          # bitwiseAndExpr
    | expr BitwiseXor expr                                                          # bitwiseXorExpr
    | expr BitwiseOr expr                                                           # bitwiseOrExpr

    // Logical expressions
    | expr (Equals | NotEquals) expr                                                # logicalEqualsExpr
    | expr (LessThan | GreaterThan | LessThanEquals | GreaterThanEquals) expr       # logicalcomparisonExpr
    | expr NOT? IN OpenParen (genericExpressionList|selectStatement) CloseParen     # logicalInExpr
    | expr NOT? BETWEEN expr AND expr                                               # logicalBetweenExpr
    | CASE expr? (WHEN expr THEN expr)+ (ELSE expr)? END                            # caseExpr
    | expr NOT? LIKE expr                                                           # logicalLikeExpr
    | expr IS NOT? NULL                                                             # logicalNullExpr
    | NOT expr                                                                      # logicalNotExpr
    | expr AND expr                                                                 # logicalAndExpr
    | expr OR expr                                                                  # logicalOrExpr
    | (ANY|ALL|SOME) expr                                                           # logicalAnyAllSomeExpr
    | expr Concat expr                                                              # concatExpr

    // Atoms
    | literal                                                                       # literalExpr
    | identifier                                                                    # identifierExpr
    ;


starExcept:
    EXCEPT (identifier | OpenParen identifier (Comma identifier)* Comma? CloseParen )
    ;

starReplace:
    REPLACE (expr AS (identifier | reservedKeyword)
            | OpenParen expr AS? (identifier | reservedKeyword)
              (Comma expr AS? (identifier | reservedKeyword))* Comma? CloseParen)
    ;

filterClause:
    FILTER OpenParen WHERE expr CloseParen
    ;

/*
4. LITERALS and HELPER RULES
------------------------------------------------------------------
This section will group together common keywords that fall into common patterns,
as well as the various literals that are available and may eventually be user-defined.

- An "Identifier" (capitalized) is a lexical token.
- An "identifier" (lowercase) is any non-reserved keyword.

As an example `DATE` would not be an Identifier, but it would be an identifier.

4.1. We won't allow cast for STRUCTs to begin. However the format will be <expr>::STRUCT(id type[, ...])
4.2. Variant does not have a literal value, it can only be cast from another literal, such as:
     1.2::VARIANT, DECIMAL(3,1) '21.7'::VARIANT
4.3 We will add the L suffix to stand for local timezone, for example: '2014-01-01 01:02:03L'.
    This is similar to the Z suffix to mean UTC, for example '2014-01-01 01:02:03Z'.
*/

identifier
    : Identifier
    | unreservedKeyword
    ;

literalType
    : BOOLEAN
    | INTEGER
    | FLOAT
    | DECIMAL (OpenParen Integer_Literal (Comma Integer_Literal)? CloseParen)?
    | STRING (OpenParen Integer_Literal CloseParen)?
    | BYTES
    | DATE
    | TIME
    | DATETIME
    | INTERVAL
    | JSON
    | VARIANT
    | STRUCT OpenParen (identifier literalType (Comma identifier literalType)*) CloseParen
    | literalType (OpenBracket CloseBracket)+
    | (Identifier|unreservedKeywordMinusType)
    ;

literal
    : NULL                                                                          # nullLiteral
    | (TRUE | FALSE)                                                                # boolLiteral
    | Integer_Literal                                                               # integerLiteral
    | Float_Literal                                                                 # floatLiteral
    | DECIMAL (OpenParen Integer_Literal (Comma Integer_Literal)? CloseParen)?
                                                                String_Literal      # decimalLiteral
    | (STRING (OpenParen Integer_Literal CloseParen)?)? String_Literal              # stringLiteral
    | (Bytes_Literal | BYTES String_Literal)                                        # bytesLiteral
    | DATE String_Literal                                                           # dateLiteral
    | TIME String_Literal                                                           # timeLiteral
    | DATETIME String_Literal                                                       # dateTimeLiteral
    | JSON String_Literal                                                           # jsonLiteral
    | INTERVAL expr timeUnit (TO timeUnit)?                                         # intervalLiteral
    | ARRAY? OpenBracket (expr (Comma expr)*)? Comma? CloseBracket                  # arrayLiteral
    | OpenBrace kvPairList? CloseBrace                                              # structLiteral
    ;

timeUnit
    : YEAR
    | QUARTER
    | MONTH
    | WEEK
    | DAY
    | HOUR
    | MINUTE
    | SECOND
    | MILLISECOND
    | MICROSECOND
    ;

extendedTimeUnit
    : YEAR
    | QUARTER
    | MONTH
    | WEEK
    | DAY
    | HOUR
    | MINUTE
    | SECOND
    | MILLISECOND
    | MICROSECOND
    | DAYOFWEEK
    | DAYOFYEAR
    ;

unreservedKeyword
    : BOOLEAN | BYTES | COUNT | DATE | DATETIME | DAY | DAYOFWEEK | DAYOFYEAR | DECIMAL
    | FILTER | FIRST | FLOAT | HOUR | INTEGER | JSON | LAST | MICROSECOND | MILLISECOND
    | MINUTE | MONTH | PERCENT | POSITION | QUARTER | REPLACE | SECOND | STRING | TIME
    | TRY_CAST | VALUES | VARIANT | WEEK | WITHOUT | YEAR
    ;

unreservedKeywordMinusType
    : COUNT | DAY | DAYOFWEEK | DAYOFYEAR | FILTER | FIRST | HOUR | LAST | MICROSECOND
    | MILLISECOND | MINUTE | MONTH | PERCENT | POSITION | QUARTER | REPLACE | SECOND
    | TRY_CAST | VALUES | WEEK | WITHOUT | YEAR
    ;

reservedKeyword
    : Other_Reserved_Keyword
    | ALL | AND | ANY | ARRAY | AS | ASC | BETWEEN | BY | CASE | CAST | COLLATE | CONTAINS | CROSS | CURRENT
    | DESC | DISTINCT | ELSE | END | EXCEPT | EXISTS | EXTRACT | FOLLOWING | FROM | FULL | GLOB | GROUP | GROUPING
    | HAVING | IF | IGNORE | IN | INNER | INTERSECT | INTERVAL | IS | JOIN | LEFT | LIKE | LIMIT | NOT | NULL
    | NULLS | OFFSET | ON | OR | ORDER | OUTER | OVER | PARTITION | PRECEDING | QUALIFY | RANGE
    | RECURSIVE | RESPECT | RIGHT | ROLLUP | ROW | ROWS | SELECT | SOME | STRUCT | TABLESAMPLE | THEN | TO
    | UNBOUNDED | UNION | UNIQUE | UNNEST | USING | WHEN | WHERE | WINDOW | WITH
    ;
