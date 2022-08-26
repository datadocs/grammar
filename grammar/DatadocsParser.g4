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
    : sqlStatement (Semi sqlStatement)* Semi | EOF
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

2.1. A FROM clause is not required. However, it is required for specifying WHERE/GROUP BY/HAVING/QUALIFY/WINDOW.
2.2. We will not support having an expression in the LIMIT or OFFSET clause (DuckDB does, BQ does not).
2.3 GROUP BY is not required for a HAVING clause, for example SELECT COUNT(1) AS c FROM tbl HAVING c > 10
2.4. We will support SELECT * EXCEPT(...). We will not support SELECT * REPLACE (which is almost never useful)
2.5. A column identifier may be of the form [server.][database.][schema.][field], so a four-part path at the maximum.
     Note that a field can continue down the path if it is a STRUCT.
2.6 A tableItem will eventually allow a table-valued function call, but we will not allow that to start.
2.7 GROUP BY clause will support standard GROUP BY and ROLLUP, but not CUBE or GROUPING SETS.
2.8 LIMIT may be expressed as either LIMIT 100, OFFSET 10 or LIMIT 100, 10.
2.9 Note that selectStar expression may not use an Alias. This will need to be checked in semantic validation.

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
    ( select | OpenParen selectStatement CloseParen )
      orderClause?
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
    : SELECT distinctModifier? selectItemList
    ;

distinctModifier
    : ALL
    | DISTINCT (ON OpenParen expr (Comma expr)* CloseParen)?
    ;

selectItemList
    : selectItem (Comma selectItem)* Comma?
    ;

selectItem
    : expr alias?
    ;

fromClause
    : FROM tableExpression
    ;

tableExpression
    : tableExpression (Comma | CROSS JOIN) tableExpression                          # crossJoinedTable
    | tableExpression (INNER? JOIN | (FULL|LEFT|RIGHT) OUTER? JOIN) tableExpression
           (ON expr | USING OpenParen identifier (Comma identifier)* CloseParen)    # conditionallyJoinedTable
    | tableItem alias? tableSample?                                                 # singleTable
    ;

tableItem
    : identifier (Dot (identifier|reservedKeyword))*                                # simplePath
    | OpenParen selectStatement CloseParen                                          # subSelect
    | OpenParen VALUES OpenParen expr (Comma expr)* CloseParen CloseParen           # valuesClause
    ;

tableSample:
    TABLESAMPLE ( Integer_Literal ROWS
               | (Integer_Literal | Float_Literal) (PERCENT | Percent))
    ;

alias
    : AS? (identifier | reservedKeyword)
    ;

whereClause
    : WHERE expr
    ;

groupByClause
    : GROUP BY groupByItemList
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

orderClause:
    ORDER BY orderItemList
    ;

orderItemList
    : orderItem (Comma orderItem)*
    ;

orderItem
    : expr (ASC|DESC)? (NULLS (FIRST|LAST))
    ;

limitClause
    : LIMIT (Integer_Literal | (Integer_Literal | Float_Literal) (PERCENT | Percent))
    ;

offsetClause
    : (Comma | OFFSET) INTEGER
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
    : OpenParen partitionByClause? orderClause? windowFrame? CloseParen
    | identifier
    ;

windowFrame
    : (RANGE|ROWS) (UNBOUNDED|expr) PRECEDING
    | CURRENT ROW
    | BETWEEN ((UNBOUNDED|expr) PRECEDING|CURRENT ROW|expr FOLLOWING)
          AND ((UNBOUNDED|expr) FOLLOWING|CURRENT ROW|expr PRECEDING)
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
    : kvPairItem (Comma kvPairItem)*
    ;

kvPairItem
    : (identifier|String_Literal) Colon literal
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
    : OpenParen expr (Comma expr)* Comma? CloseParen                                # parenExpr
    | OpenParen simpleSelect CloseParen                                             # subSelectExpr
    | literal                                                                       # literalExpr

    // Unambiguous (leading) expressions
    | CASE expr? (WHEN expr THEN expr)+ (ELSE expr)? END                            # caseExpr
    | EXTRACT OpenParen timeUnit FROM expr CloseParen                               # extractExpr
    | (SAFE_CAST|TRY_CAST|CAST) OpenParen expr AS literalType CloseParen            # castFunctionExpr

    // Other custom expressions
    | expr TypeCast literalType                                                     # castOperatorExpr
    | expr COLLATE (WITH|WITHOUT) CASE                                              # collateExpr

    // Arithmetic expressions
    | (Plus | Minus) expr                                                           # arithmeticUnaryPlusMinusExpr
    | BitwiseNot expr                                                               # bitwiseNotExpr
    | expr (Star | Slash) expr                                                      # arithmeticTimesDivExpr
    | expr Concat expr                                                              # concatExpr
    | expr (Plus | Minus) expr                                                      # arithmeticPlusMinusExpr

    // Bitwise expressions (bitwiseNot above)
    | expr (BitShiftLeft | BitShiftRight) expr                                      # bitwiseShiftExpr
    | expr BitwiseAnd expr                                                          # bitwiseAndExpr
    | expr BitwiseXor expr                                                          # bitwiseXorExpr
    | expr BitwiseOr expr                                                           # bitwiseOrExpr

    // Logical expressions
    | expr (Equals | NotEquals) expr                                                # logicalEqualsExpr
    | expr (LessThan | GreaterThan | LessThanEquals | GreaterThanEquals) expr       # logicalcomparisonExpr
    | expr NOT? BETWEEN expr AND expr                                               # logicalBetweenExpr
    | expr NOT? LIKE expr                                                           # logicalLikeExpr
    | expr IS NOT? NULL                                                             # logicalNullExpr
    | NOT expr                                                                      # logicalNotExpr
    | expr AND expr                                                                 # logicalAndExpr
    | expr OR expr                                                                  # logicalOrExpr

    | expr NOT? IN OpenParen (genericExpressionList|simpleSelect) CloseParen        # logicalInExpr
    | EXISTS OpenParen simpleSelect CloseParen                                      # logicalExistsExpr
    | Equals ANY OpenParen simpleSelect CloseParen                                  # logicalAnyExpr

    // Function expressions (should the leading `expr` be qualified?
    | expr OpenParen Star? CloseParen                                               # functionCallNoParamsExpr
    | expr OpenParen DISTINCT? (genericExpressionList |
             namedExpressionList (Comma genericExpressionList)? CloseParen)         # functionCallParamsExpr

    // Field access expressions
    | Star starExcept?                                                              # starExpr
    | expr Dot Star starExcept?                                                     # pathAccessStarExpr
    | expr (OpenBracket expr (Colon expr)? CloseBracket  )                          # pathAccessArrayExpr
    | expr Dot (identifier|reservedKeyword)                                         # pathAccessFieldExpr

    | identifier                                                                    # identifierExpr

    ;

starExcept:
    EXCEPT OpenParen identifier (Comma identifier)* CloseParen
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
*/

identifier
    : Identifier
    | unreservedKeyword
    ;

literalType
    : BOOLEAN
    | INTEGER
    | FLOAT
    | DECIMAL (OpenParen Integer_Literal Comma Integer_Literal CloseParen)?
    | STRING (OpenParen Integer_Literal CloseParen)?
    | BYTES
    | DATE
    | TIME
    | DATETIME
    | JSON
    | VARIANT
    | (geographyType | GEOGRAPHY OpenParen geographyType CloseParen)
    | literalType (OpenBracket CloseBracket)+
    | identifier
//  | STRUCT OpenParen (identifier literalType (Comma identifier literalType)*) CloseParen
    ;

literal
    : NULL                                                                          # nullLiteral
    | (TRUE | FALSE)                                                                # boolLiteral
    | Integer_Literal                                                               # integerLiteral
    | Float_Literal                                                                 # floatLiteral
    | DECIMAL (OpenParen Integer_Literal Comma Integer_Literal CloseParen)?
                                                                String_Literal      # decimalLiteral
    | (STRING (OpenParen Integer_Literal CloseParen)?)? String_Literal              # stringLiteral
    | (Bytes_Literal | BYTES String_Literal)                                        # bytesLiteral
    | DATE String_Literal                                                           # dateLiteral
    | TIME String_Literal                                                           # timeLiteral
    | DATETIME String_Literal                                                       # dateTimeLiteral
    | JSON String_Literal                                                           # jsonLiteral
    | (geographyType | GEOGRAPHY OpenParen geographyType CloseParen) String_Literal # geoLiteral
    | INTERVAL String_Literal timeUnit (TO timeUnit)?                               # intervalLiteral
    | OpenBracket (literal (Comma literal)*)? CloseBracket                          # arrayLiteral
    | OpenBrace kvPairList? CloseBrace                                              # structLiteral
    ;

geographyType
    : POINT
    | LINE
    | POLYGON
    | MULTIPOINT
    | MULTILINE
    | GEOMETRYCOLLECTION
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
    ;

unreservedKeyword
    : BOOLEAN | BYTES | COUNT | DATE | DATETIME | DAY | DECIMAL | FIRST | FLOAT | GEOGRAPHY
    | GEOMETRYCOLLECTION | HOUR | INTEGER | JSON | LAST | LINE | MINUTE | MONTH | MULTILINE
    | MULTIPOINT | PERCENT | POINT | POLYGON | QUARTER | REPLACE | SAFE_CAST | SECOND
    | STRING | TIME | TRY_CAST | VALUES | VARIANT | WEEK | WITHOUT | YEAR
    ;

reservedKeyword
    : Other_Reserved_Keyword
    | ALL | AND | ANY | ARRAY | AS | ASC | BETWEEN | BY | CASE | CAST | COLLATE | CROSS | CURRENT
    | DESC | DISTINCT | ELSE | END | EXCEPT | EXISTS | EXTRACT | FOLLOWING | FROM | FULL | GROUP
    | HAVING | IN | INNER | INTERSECT | INTERVAL | IS | JOIN | LEFT | LIKE | LIMIT | NOT | NULL
    | NULLS | OFFSET | ON | OR | ORDER | OUTER | OVER | PARTITION | PRECEDING | QUALIFY | RANGE
    | RECURSIVE | RIGHT | ROLLUP | ROW | ROWS | SELECT | SOME | STRUCT | TABLESAMPLE | THEN | TO
    | UNBOUNDED | UNION | UNIQUE | USING | WHEN | WHERE | WINDOW | WITH
    ;

