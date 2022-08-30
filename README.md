# Grammar
# Syntax

Antlr4 grammar for SQL `SELECT` statement. Overview of syntax located at [SYNTAX.md](https://github.com/datadocs/grammar/blob/master/SYNTAX.md).

You can test this by doing:

```
$ cd grammar
$ java -jar ../antlr-4.10.1-complete.jar Datadocs*.g4 -o out
$ javac Datadocs*.java
$ time java org.antlr.v4.gui.TestRig Datadocs testRoot ../../test/duckdb/legacy.txt
```
