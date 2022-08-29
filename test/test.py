import sys
import time
import os
import re

sys.path.append('/Users/david/Desktop/grammar/out')

from antlr4 import *
from antlr4.error.ErrorListener import *
from DatadocsLexer import DatadocsLexer
from DatadocsParser import DatadocsParser

'''
To run:

export grammar_dir=/Users/david/Desktop/grammar/grammar 
export script=/Users/david/Desktop/grammar/test/test.py 
export file=/Users/david/Desktop/grammar/test/duckdb/duckdb_selects.txt

alias rebuild='antlr4 -Dlanguage=Python3 -o "$( dirname "$grammar_dir" )"/out $grammar_dir/*.g4'
python $script $file

And to run the java parser on an output file:


'''


class AntlrException(Exception): pass
class VerboseListener(ErrorListener) :
    def syntaxError(self, recognizer, offendingSymbol, line, column, msg, e):
        error_msg = f"ERROR: line {line}: {column} at {offendingSymbol}: {msg}"
        raise AntlrException(error_msg)

def parseSQL(text):
    lexer = DatadocsLexer(InputStream(text))
    stream = CommonTokenStream(lexer)
    parser = DatadocsParser(stream)
    parser.removeErrorListeners()
    parser.addErrorListener(VerboseListener())
    tree = parser.testRoot()
    # print (tree.toStringTree(recog=parser))
    return tree


if __name__ == '__main__':
    if len(sys.argv != 2):
        statements = ["SELECT 1", "asdf"]
        base = os.path.dirname(os.path.realpath(__file__))
    else:
        base = os.path.dirname(os.path.realpath(sys.argv[-1]))
        with open(sys.argv[-1]) as f: 
            text = f.read()
        statements = [item.strip().rstrip(';') + ';' for item in text.split('\n') if item.strip()]

    ok_file, error_file = open(base + '/ok.txt', 'w'), open(base + '/error.txt', 'w')
    ok_count = error_count = 0
    t0 = time.time()
    max_time = 0

    for i, statement in enumerate(statements):
        if statement.startswith('--'): continue
        t1 = time.time()
        try:
            tree = parseSQL(statement)
            successful = True
        except Exception as e:
            successful = False
            print (statement)
            #  if error_count > 10: sys.exit(1)
        finally:
            if successful:
                ok_file.write(statement + '\n'); ok_count += 1
            else:
                error_file.write(statement + '\n'); error_count += 1
        t2 = time.time()
        if t2-t1 > max_time:
            #  print (t2-t1, '\n', statement)
            max_time = t2-t1
        total_time = t2 - t0
        avg_time = total_time / (i+1)
        #  print ('%d. %-6s %.5f (OK: %1d | Error: %1d | MaxTime: %.4f | AvgTime: %.4f |TotalTime: %.4f)' % (i+1, 'OK' if successful else 'ERROR', t2-t1, ok_count, error_count, max_time, avg_time, total_time))


