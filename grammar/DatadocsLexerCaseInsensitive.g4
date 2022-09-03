lexer grammar DatadocsLexerCaseInsensitive;
options { caseInsensitive=true; }

/*

1. NAMING CONVENTIONS
------------------------------------------------------------------
We will use the following naming conventions for lexical tokens.

1. Keywords will be named exactly as they are spelled in ALL_CAPS.
   Data types may have multiple aliases and will converge to a single name.

   Examples: SELECT, FROM, WHERE, OR, CONCAT, BOOLEAN ("BOOL" | "BOOLEAN")


2. Non-alphabetic mathematical or operator symbols will be CamelCased.
   If the symbol may have multiple uses (".") its name will be the symbol ("Dot").
   If the symbol only has one use (">>") its name will be the action ("BitShiftRight")

   Examples: Comma, OpenParen, Tilda, BitwiseOr, Concat ("||")


3. All other special tokens will be Camel_Case_With_Underscore.

   Examples: String_Literal, Single_Line_Comment, Identifier (special case: no underscore)

*/


/*
2. OPERATORS & NON-KEYWORD SYMBOLS
------------------------------------------------------------------
*/
OpenParen:                      '(';
CloseParen:                     ')';
OpenBracket:                    '[';
CloseBracket:                   ']';
OpenBrace:                      '{';
CloseBrace:                     '}';
Comma:                          ',';
Semi:                           ';';
Colon:                          ':';
Dot:                            '.';
Star:                           '*';
Plus:                           '+';
Minus:                          '-';
Slash:                          '/';
Equals:                         '=';
NotEquals:                      '!=' | '<>';
LessThan:                       '<';
GreaterThan:                    '>';
LessThanEquals:                 '<=';
GreaterThanEquals:              '>=';
TypeCast:                       '::';
Percent:                        '%';
BitShiftLeft:                   '<<';
BitShiftRight:                  '>>';
BitwiseAnd:                     '&';
BitwiseXor:                     '^';
BitwiseOr:                      '|';
BitwiseNot:                     '~';
NamedParam:                     ':=' | '=>';
Concat:                         '||';


/*
3. LITERALS
------------------------------------------------------------------
1. NUMBERS are accepted as either an integer, float, or scientific number.

Examples: 1.2, 1, .23, 1., 2e3, 12.3e-12

2. STRING and BYTES may be enclosed with a single or double quote.
Bytes literals have the same format, prefixed with a 'B' or 'b'.
They may be escaped with a \ character. A Regex/Raw string is prefixed
with an 'R' or 'r' and removes the need to escape backslashes in a regex.
Regex used here is: normal* ( special normal* )*

Examples: "hello", 'hello', 'he''llo', b'ab12', B"1\"2\n".

*/

Integer_Literal: (Digit+ | HexNumber);
Float_Literal: (Digit+ Dot Digit* | Dot? Digit+ | HexNumber) Exponent?;
Hex_Literal: ('0x' HexDigit+) Exponent?;

fragment HexNumber: ('0x' HexDigit+);
fragment Exponent: 'E' [+-]? Digit+;
fragment HexDigit: [0-9a-f];
fragment Digit: [0-9];


String_Literal
    : 'R'? (
       DQuoteNewlineEscape
     | SQuoteNewlineEscape
   );

Bytes_Literal
    : 'B' (
       DQuoteNewlineEscape
     | SQuoteNewlineEscape
    );


fragment DQuoteNewlineEscape
    : '"' ~["\\]*('\\' . ~["\\]*)* '"'
    ;

fragment SQuoteNewlineEscape
    : '\'' ~['\\]*('\\' . ~['\\]*)* '\''
    ;

/*
4. KEYWORDS
------------------------------------------------------------------
Keywords may be either RESERVED or UNRESERVED tokens. RESERVED tokens mean that
they may not be used directly as an identifier unless quoted. UNRESERVED tokens
are more helper tokens to refer to from the parser file.

We will also respect RESERVED tokens from BigQuery or DuckDB, and even if currently unused
in our application. These will be placed in the "Other_Reserved_Keyword" group.

References: BigQuery: https://cloud.google.com/bigquery/docs/reference/standard-sql/lexical#reserved_keywords
            DuckDB: https://github.com/duckdb/duckdb/blob/master/third_party/libpg_query/include/parser/kwlist.hpp
*/

// 4.1. RESERVED (Used)
ALL:                            'ALL';
AND:                            'AND';
ANY:                            'ANY';
ARRAY:                          'ARRAY';
AS:                             'AS';
ASC:                            'ASC';
BETWEEN:                        'BETWEEN';
BY:                             'BY';
CASE:                           'CASE';
CAST:                           'CAST';
COLLATE:                        'COLLATE';
CONTAINS:                       'CONTAINS';
CROSS:                          'CROSS';
CURRENT:                        'CURRENT';
DESC:                           'DESC';
DISTINCT:                       'DISTINCT';
ELSE:                           'ELSE';
END:                            'END';
EXCEPT:                         'EXCEPT'|'EXCLUDE';
EXISTS:                         'EXISTS';
EXTRACT:                        'EXTRACT';
FALSE:                          'FALSE';
FOLLOWING:                      'FOLLOWING';
FROM:                           'FROM';
FULL:                           'FULL';
GLOB:                           'GLOB';
GROUP:                          'GROUP';
GROUPING:                       'GROUPING';
HAVING:                         'HAVING';
IGNORE:                         'IGNORE';
IF:                             'IF';
IN:                             'IN';
INNER:                          'INNER';
INTERSECT:                      'INTERSECT';
INTERVAL:                       'INTERVAL';
IS:                             'IS';
JOIN:                           'JOIN';
LEFT:                           'LEFT';
LIKE:                           'LIKE';
LIMIT:                          'LIMIT';
NOT:                            'NOT';
NULL:                           'NULL';
NULLS:                          'NULLS';
OFFSET:                         'OFFSET';
ON:                             'ON';
OR:                             'OR';
ORDER:                          'ORDER';
OUTER:                          'OUTER';
OVER:                           'OVER';
PARTITION:                      'PARTITION';
PRECEDING:                      'PRECEDING';
QUALIFY:                        'QUALIFY';
RANGE:                          'RANGE';
RECURSIVE:                      'RECURSIVE';
RESPECT:                        'RESPECT';
RIGHT:                          'RIGHT';
ROLLUP:                         'ROLLUP';
ROW:                            'ROW';
ROWS:                           'ROWS';
SELECT:                         'SELECT';
SOME:                           'SOME';
STRUCT:                         'STRUCT';
TABLESAMPLE:                    'TABLESAMPLE';
THEN:                           'THEN';
TO:                             'TO';
TRUE:                           'TRUE';
UNBOUNDED:                      'UNBOUNDED';
UNION:                          'UNION';
UNIQUE:                         'UNIQUE';
UNNEST:                         'UNNEST';
USING:                          'USING';
WHEN:                           'WHEN';
WHERE:                          'WHERE';
WINDOW:                         'WINDOW';
WITH:                           'WITH';


// 4.2. RESERVED (Currently Unused)
fragment ANALYSE:               'ANALYSE';
fragment ANALYZE:               'ANALYZE';                  
fragment ASSERT_ROWS_MODIFIED:  'ASSERT_ROWS_MODIFIED';     
fragment ASYMMETRIC:            'ASYMMETRIC';               
fragment AT:                    'AT';                       
fragment BOTH:                  'BOTH';                     
fragment CHECK:                 'CHECK';                    
fragment COLUMN:                'COLUMN';                   
fragment CONSTRAINT:            'CONSTRAINT';               
fragment CREATE:                'CREATE';
fragment CUBE:                  'CUBE';                     
fragment CURRENT_TIME:          'CURRENT_TIME';             
fragment CURRENT_TIMESTAMP:     'CURRENT_TIMESTAMP';        
fragment DEFAULT:               'DEFAULT';
fragment DEFERRABLE:            'DEFERRABLE';               
fragment DEFINE:                'DEFINE';                   
fragment DO:                    'DO';                       
fragment ENUM:                  'ENUM';                     
fragment ESCAPE:                'ESCAPE';                   
fragment FETCH:                 'FETCH';
fragment FOR:                   'FOR';                      
fragment FOREIGN:               'FOREIGN';                  
fragment GRANT:                 'GRANT';
fragment GROUPS:                'GROUPS';
fragment HASH:                  'HASH';                     
fragment INITIALLY:             'INITIALLY';
fragment INTO:                  'INTO';                     
fragment LATERAL:               'LATERAL';                  
fragment LEADING:               'LEADING';                  
fragment LOCALTIME:             'LOCALTIME';                
fragment LOCALTIMESTAMP:        'LOCALTIMESTAMP';           
fragment LOOKUP:                'LOOKUP';                   
fragment MERGE:                 'MERGE';                    
fragment MODIFIED:              'MODIFIED';                 
fragment NATURAL:               'NATURAL';                  
fragment NEW:                   'NEW';                      
fragment NO:                    'NO';                       
fragment OF:                    'OF';                       
fragment ONLY:                  'ONLY';                     
fragment PLACING:               'PLACING';                  
fragment PRIMARY:               'PRIMARY';                  
fragment PROTO:                 'PROTO';
fragment REFERENCES:            'REFERENCES';
fragment RESERVED_PREFIX:       ('DD'|'XL') ('_' [a-z0-9_]*)?;
fragment RETURNING:             'RETURNING';
fragment SET:                   'SET';
fragment SYMMETRIC:             'SYMMETRIC';                
fragment TABLE:                 'TABLE';                    
fragment TRAILING:              'TRAILING';                 
fragment TREAT:                 'TREAT';                    
fragment USER:                  'USER';
fragment VARIADIC:              'VARIADIC';                 
fragment WITHIN:                'WITHIN';                   

Other_Reserved_Keyword
  : ANALYSE
  | ANALYZE
  | ASSERT_ROWS_MODIFIED
  | ASYMMETRIC
  | AT
  | BOTH
  | CHECK
  | COLUMN
  | CONSTRAINT
  | CREATE
  | CUBE
  | CURRENT_TIME
  | CURRENT_TIMESTAMP
  | DEFAULT
  | DEFERRABLE
  | DEFINE
  | DO
  | ENUM
  | ESCAPE
  | FETCH
  | FOR
  | FOREIGN
  | GRANT
  | GROUPS
  | HASH
  | INITIALLY
  | INTO
  | LATERAL
  | LEADING
  | LOCALTIME
  | LOCALTIMESTAMP
  | LOOKUP
  | MERGE
  | MODIFIED
  | NATURAL
  | NEW
  | NO
  | OF
  | ONLY
  | PLACING
  | PRIMARY
  | PROTO
  | REFERENCES
  | RESERVED_PREFIX
  | RETURNING
  | SET
  | SYMMETRIC
  | TABLE
  | TRAILING
  | TREAT
  | USER
  | VARIADIC
  | WITHIN
  ;

// 4.3. OTHER KEYWORDS
// Note that some of these keywords may be restricted in certain contexts.
// For example, the keyword "BOOLEAN" may not be used as the name of a custom type,
// because it is already the name of a type.
// Note: INTERVAL, STRUCT, and ARRAY are RESERVED. GEOGRAPHY is via Constructor
BOOLEAN:                        'BOOLEAN' | 'BOOL' ;
INTEGER:                        'INTEGER' | 'INT';
FLOAT:                          'FLOAT' | 'REAL';
DECIMAL:                        'DECIMAL' | 'NUMERIC';
STRING:                         'STRING' | 'TEXT' | 'VARCHAR';
BYTES:                          'BYTES' | 'BINARY' | 'BLOB' | 'BYTEA';
DATE:                           'DATE';
TIME:                           'TIME';
DATETIME:                       'DATETIME' | 'TIMESTAMP';
JSON:                           'JSON';
VARIANT:                        'VARIANT';

MICROSECOND:                    'MICROSECOND' 'S'?;
MILLISECOND:                    'MILLISECOND' 'S'?;
SECOND:                         'SECOND' 'S'?;
MINUTE:                         'MINUTE' 'S'?;
HOUR:                           'HOUR' 'S'?;
DAY:                            'DAY' 'S'?;
WEEK:                           'WEEK' 'S'?;
MONTH:                          'MONTH' 'S'?;
QUARTER:                        'QUARTER' 'S'?;
YEAR:                           'YEAR' 'S'?;
DAYOFWEEK:                      'DAYOFWEEK' | 'DOW';
DAYOFYEAR:                      'DAYOFYEAR' | 'DOY';

COUNT:                          'COUNT';
FILTER:                         'FILTER';
FIRST:                          'FIRST';
LAST:                           'LAST';
PERCENT:                        'PERCENT';
POSITION:                       'POSITION';
REPLACE:                        'REPLACE';
TRY_CAST:                       'TRY_CAST' | 'SAFE_CAST';
VALUES:                         'VALUES';
WITHOUT:                        'WITHOUT';


/*
5. IDENTIFIERS, COMMENTS, and WHITESPACE
------------------------------------------------------------------
Identiers must be quoted with `backticks` if they clash with a reserved keyword.
However, within a dotted path, backticks are not necessary and are handled by
the special mode defined below.

Examples (within a SELECT clause):
    SELECT myIdentifier, `select`, tbl . select, tbl . new[0] . select, tbl.`123`
    FROM tbl
*/

Identifier
    : PureIdentifier
    | BQuoteQuoteEscape
    ;

fragment PureIdentifier
    : [A-Z_] [A-Z_0-9]*
    ;

fragment BQuoteQuoteEscape
    : '`' ~[`]*('``' ~[`]*)* '`'
    ;

Single_Line_Comment
    : ('--'|'#') ~ [\r\n]* -> skip
    ;     

Multi_Line_Comment
    : '/*' .*? ('*/' | EOF) -> skip
    ;

White_Space
    : [ \t\r\n] -> skip
    ;

