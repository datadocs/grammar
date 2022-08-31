# null
SELECT NULL;
SELECT Null;
SELECT null;

# boolean
SELECT true;
SELECT TRUE;
SELECT False;

# int
SELECT 12;
SELECT -101;
SELECT 0xA2;
SELECT -102020202020212123123;

# float
SELECT 12.3;
SELECT -2.3e7;
SELECT -3.E+6;
SELECT 102e+4;

# decimal
SELECT DECIMAL '2.4';
SELECT NUMERIC '2.4e12';
SELECT DECIMAL(3,2) '-2.412';
SELECT NUMERIC(2) '-2.412';

# string
SELECT "Hello";
SELECT 'Hello';
SELECT r'\(.+?'; # raw/regex literal, turns into '\(.+?'
SELECT R'\(.+?';
SELECT "\x01\x02\x00\x12\x";
SELECT "Hi \" Are \" You there?";
SELECT 'Hi \' Are you \' there?';

# bytes
SELECT b'123';
select b'12\'3';
select B"12\'\"'3";

# date
SELECT DATE '2014-01-01';
SELECT DATE '1000-01-01';
SELECT DATE '1014-1-1';
SELECT DATE '0001-1-1';

# time
SELECT TIME '12:30:00';
SELECT TIME '12:30:00.45';
SELECT TIME '12:30:00.45123123123123123123123'; # truncate it to 6
SELECT TIME '1:1:1';

# datetime
SELECT DATETIME '2014-01-01';
SELECT DATETIME '2014-01-01T01:02:03';
SELECT DATETIME '2014-01-01T01:02:03.123';
SELECT DATETIME '2014-01-01T01:02:03.12312312312312'; # truncate it to 6
SELECT TIMESTAMP '2014-01-01 01:02:03';
SELECT TIMESTAMP '2014-01-01 01:02:03Z';
SELECT TIMESTAMP '2014-01-01 01:02:03L'; # allow 'L' for local timezone
SELECT TIMESTAMP '2008-12-25 15:30:00-08:00';
SELECT TIMESTAMP '2008-12-25 15:30:00-2';

# interval
SELECT INTERVAL 4 DAY;
SELECT INTERVAL 4 DAYS;
SELECT INTERVAL '4' DAY;
SELECT INTERVAL '3.5' SECOND;
SELECT INTERVAL '3.5' SECONDS;
SELECT INTERVAL '0.001' SECOND;
SELECT INTERVAL '10:20:30' HOURS TO SECOND;
SELECT INTERVAL '1-2' YEARS TO MONTHS;
SELECT INTERVAL '1 15' MONTH TO DAY;
SELECT INTERVAL '1 5:30' DAYS TO MINUTE;
SELECT INTERVAL '1 30:7000' DAY TO MINUTE;

# geography -- no direct literals, requires a function to type
SELECT ST_GEOGFROM(null);
SELECT ST_GEOGFROM('POINT EMPTY');
SELECT ST_GEOGFROM('POINT(0 0)');
SELECT ST_GEOGFROM('MULTIPOINT(0 0, 1 1)');
SELECT ST_GEOGFROM('LINESTRING(1 2, 2 1)');
SELECT ST_GEOGFROM('MULTILINESTRING((2 2, 3 4), (5 6, 7 7))');
SELECT ST_GEOGFROM('POLYGON((0 0, 0 2, 2 2, 2 0, 0 0))');
SELECT ST_GEOGFROM('MULTIPOLYGON(((0 -1, 1 0, 0 1, 0 -1)), ((1 0, 2 -1, 2 1, 1 0)))');
SELECT ST_GEOGFROM('GEOMETRYCOLLECTION (POINT (40 10), LINESTRING empty)');
SELECT ST_GEOGFROM('GEOMETRYCOLLECTION (POINT (40 10), LINESTRING (10 10, 20 20, 10 40))');

# json
SELECT JSON "{}";
SELECT JSON '{"x":2}';
SELECT JSON '2';
SELECT JSON "[1,2,3]";
SELECT JSON "{\"x\":4}";
SELECT JSON '[{"a": 2}, 4, 1.2, {"x": false}]';
SELECT JSON '{"this is a fie`ld x":"4\\t"}';
SELECT JSON '{"id":10,"type":"fruit","name":"apple","on_menu":true,"recipes":{"salads":[{"id":2001,"type":"Walnut Apple Salad"},{"id":2002,"type":"Apple Spinach Salad"}],"desserts":[{"id":3001,"type":"Apple Pie"},{"id":3002,"type":"Apple Scones"},{"id":3003,"type":"Apple Crumble"}]}}';

# struct
SELECT (1, 2, 3);
SELECT (1,);
SELECT ((1,2), 2, (1,2));
SELECT {`something new`: 1, 'hi': x, "ok": 3, once: '4', select: 5};
SELECT {x: 1, y: 2, z: (1,(1,2))};
SELECT {Age: 14.2, Birth: DATE '2014-01-01',};

# literals
# not directly accessed by the application, handled at storage level
# however, see Array/Typeof section for an example of how it may arise.

# array
SELECT [];
SELECT [1,2,3];
SELECT [5];
SELECT [1,2,null]; # Valid literal, even if particular backend (BQ) doesnt support it
SELECT ["1", DATE '2014-01-01',];
SELECT [[], [], [[], []]]; # Again, valid literal even if not supported by backend
SELECT [{x: 1}, {x: 2}, {x: 3}];
SELECT [(1,2,3), {x: 1, y: 2, z: (1,(1,2))}, null, INTERVAL '1 15' MONTH TO DAY];

# typeof
SELECT DD_TYPEOF([]);                       # null[]
SELECT DD_TYPEOF(null);                     # null
SELECT DD_TYPEOF(1);                        # int
SELECT DD_TYPEOF({x:1});                    # struct(x int)
SELECT DD_TYPEOF([{x:1}, {x:1}]);           # struct(x int)[]
SELECT DD_TYPEOF([{x:1}, JSON "null"]);     # variant[]
