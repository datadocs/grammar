lexer grammar DatadocsLexer;

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

fragment HexNumber: ('0' X HexDigit+);
fragment Exponent: E [+-]? Digit+;
fragment HexDigit: [0-9a-fA-F];
fragment Digit: [0-9];


String_Literal
    : R ? (
       DQuoteNewlineEscape
     | SQuoteNewlineEscape
   );

Bytes_Literal
    : B (
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
ALL:                            A L L;
AND:                            A N D;
ANY:                            A N Y;
ARRAY:                          A R R A Y;
AS:                             A S;
ASC:                            A S C;
BETWEEN:                        B E T W E E N;
BY:                             B Y;
CASE:                           C A S E;
CAST:                           C A S T;
COLLATE:                        C O L L A T E;
CONTAINS:                       C O N T A I N S;
CROSS:                          C R O S S;
CURRENT:                        C U R R E N T;
DESC:                           D E S C;
DISTINCT:                       D I S T I N C T;
ELSE:                           E L S E;
END:                            E N D;
EXCEPT:                         E X C E P T | E X C L U D E;
EXISTS:                         E X I S T S;
EXTRACT:                        E X T R A C T;
FALSE:                          F A L S E;
FOLLOWING:                      F O L L O W I N G;
FROM:                           F R O M;
FULL:                           F U L L;
GLOB:                           G L O B;
GROUP:                          G R O U P;
GROUPING:                       G R O U P I N G;
HAVING:                         H A V I N G;
IGNORE:                         I G N O R E;
IF:                             I F;
IN:                             I N;
INNER:                          I N N E R;
INTERSECT:                      I N T E R S E C T;
INTERVAL:                       I N T E R V A L;
IS:                             I S;
JOIN:                           J O I N;
LEFT:                           L E F T;
LIKE:                           L I K E;
LIMIT:                          L I M I T;
NOT:                            N O T;
NULL:                           N U L L;
NULLS:                          N U L L S;
OFFSET:                         O F F S E T;
ON:                             O N;
OR:                             O R;
ORDER:                          O R D E R;
OUTER:                          O U T E R;
OVER:                           O V E R;
PARTITION:                      P A R T I T I O N;
PRECEDING:                      P R E C E D I N G;
QUALIFY:                        Q U A L I F Y;
RANGE:                          R A N G E;
RECURSIVE:                      R E C U R S I V E;
RESPECT:                        R E S P E C T;
RIGHT:                          R I G H T;
ROLLUP:                         R O L L U P;
ROW:                            R O W;
ROWS:                           R O W S;
SELECT:                         S E L E C T;
SOME:                           S O M E;
STRUCT:                         S T R U C T;
TABLESAMPLE:                    T A B L E S A M P L E;
THEN:                           T H E N;
TO:                             T O;
TRUE:                           T R U E;
UNBOUNDED:                      U N B O U N D E D;
UNION:                          U N I O N;
UNIQUE:                         U N I Q U E;
UNNEST:                         U N N E S T;
USING:                          U S I N G;
WHEN:                           W H E N;
WHERE:                          W H E R E;
WINDOW:                         W I N D O W;
WITH:                           W I T H;


// 4.2. RESERVED (Currently Unused)
fragment ANALYSE:               A N A L Y S E;
fragment ANALYZE:               A N A L Y Z E;
fragment ASSERT_ROWS_MODIFIED:  A S S E R T '_' R O W S '_' M O D I F I E D;
fragment ASYMMETRIC:            A S Y M M E T R I C;
fragment AT:                    A T;
fragment BOTH:                  B O T H;
fragment CHECK:                 C H E C K;
fragment COLUMN:                C O L U M N;
fragment CONSTRAINT:            C O N S T R A I N T;
fragment CREATE:                C R E A T E;
fragment CUBE:                  C U B E;
fragment CURRENT_TIME:          C U R R E N T '_' T I M E;
fragment CURRENT_TIMESTAMP:     C U R R E N T '_' T I M E S T A M P;
fragment DEFAULT:               D E F A U L T;
fragment DEFERRABLE:            D E F E R R A B L E;
fragment DEFINE:                D E F I N E;
fragment DO:                    D O;
fragment ENUM:                  E N U M;
fragment ESCAPE:                E S C A P E;
fragment FETCH:                 F E T C H;
fragment FOR:                   F O R;
fragment FOREIGN:               F O R E I G N;
fragment GRANT:                 G R A N T;
fragment GROUPS:                G R O U P S;
fragment HASH:                  H A S H;
fragment INITIALLY:             I N I T I A L L Y;
fragment INTO:                  I N T O;
fragment LATERAL:               L A T E R A L;
fragment LEADING:               L E A D I N G;
fragment LOCALTIME:             L O C A L T I M E;
fragment LOCALTIMESTAMP:        L O C A L T I M E S T A M P;
fragment LOOKUP:                L O O K U P;
fragment MERGE:                 M E R G E;
fragment MODIFIED:              M O D I F I E D;
fragment NATURAL:               N A T U R A L;
fragment NEW:                   N E W;
fragment NO:                    N O;
fragment OF:                    O F;
fragment ONLY:                  O N L Y;
fragment PLACING:               P L A C I N G;
fragment PRIMARY:               P R I M A R Y;
fragment PROTO:                 P R O T O;
fragment REFERENCES:            R E F E R E N C E S;
fragment RESERVED_PREFIX:       (D D|X L) ('_' [A-Za-z0-9_]*)?;
fragment RETURNING:             R E T U R N I N G;
fragment SET:                   S E T;
fragment SYMMETRIC:             S Y M M E T R I C;
fragment TABLE:                 T A B L E;
fragment TRAILING:              T R A I L I N G;
fragment TREAT:                 T R E A T;
fragment USER:                  U S E R;
fragment VARIADIC:              V A R I A D I C;
fragment WITHIN:                W I T H I N;


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
BOOLEAN:                        B O O L E A N | B O O L;
INTEGER:                        I N T E G E R | I N T;
FLOAT:                          F L O A T | R E A L;
DECIMAL:                        D E C I M A L | N U M E R I C;
STRING:                         S T R I N G | T E X T | V A R C H A R;
BYTES:                          B Y T E S | B I N A R Y | B L O B | B Y T E A;
DATE:                           D A T E;
TIME:                           T I M E;
DATETIME:                       D A T E T I M E | T I M E S T A M P;
JSON:                           J S O N;
VARIANT:                        V A R I A N T;

MICROSECOND:                    M I C R O S E C O N D S?;
MILLISECOND:                    M I L L I S E C O N D S?;
SECOND:                         S E C O N D S?;
MINUTE:                         M I N U T E S?;
HOUR:                           H O U R S?;
DAY:                            D A Y S? ;
WEEK:                           W E E K S?;
MONTH:                          M O N T H S?;
QUARTER:                        Q U A R T E R S?;
YEAR:                           Y E A R S?;
DAYOFWEEK:                      D A Y O F W E E K | D O W;
DAYOFYEAR:                      D A Y O F Y E A R | D O Y;

COUNT:                          C O U N T;
FILTER:                         F I L T E R;
FIRST:                          F I R S T;
LAST:                           L A S T;
PERCENT:                        P E R C E N T;
POSITION:                       P O S I T I O N;
REPLACE:                        R E P L A C E;
TRY_CAST:                       T R Y '_' C A S T | S A F E '_' C A S T;
VALUES:                         V A L U E S;
WITHOUT:                        W I T H O U T;




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
    : [A-Za-z_] [A-Za-z_0-9]*
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

fragment A: [aA];
fragment B: [bB];
fragment C: [cC];
fragment D: [dD];
fragment E: [eE];
fragment F: [fF];
fragment G: [gG];
fragment H: [hH];
fragment I: [iI];
fragment J: [jJ];
fragment K: [kK];
fragment L: [lL];
fragment M: [mM];
fragment N: [nN];
fragment O: [oO];
fragment P: [pP];
fragment Q: [qQ];
fragment R: [rR];
fragment S: [sS];
fragment T: [tT];
fragment U: [uU];
fragment V: [vV];
fragment W: [wW];
fragment X: [xX];
fragment Y: [yY];
fragment Z: [zZ];