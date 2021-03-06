library("testthat")

test_that("translateSQL sql server -> Oracle DATEDIFF", {
  sql <- translateSql("SELECT DATEDIFF(dd,drug_era_start_date,drug_era_end_date) FROM drug_era;",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql, "SELECT   (drug_era_end_date - drug_era_start_date)  FROM  drug_era ;")
})


test_that("translateSQL sql server -> Oracle DATEADD", {
  sql <- translateSql("SELECT DATEADD(dd,30,drug_era_end_date) FROM drug_era;",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql, "SELECT   (drug_era_end_date + 30)  FROM  drug_era ;")
})

test_that("translateSQL sql server -> Oracle USE", {
  sql <- translateSql("USE vocabulary;", sourceDialect = "sql server", targetDialect = "oracle")$sql
  expect_equal(sql, "ALTER SESSION SET current_schema =  vocabulary;")
})

test_that("translateSQL sql server -> Oracle DROP TABLE IF EXISTS", {
  sql <- translateSql("IF OBJECT_ID('cohort', 'U') IS NOT NULL DROP TABLE cohort;",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql,
               "BEGIN\n  EXECUTE IMMEDIATE 'TRUNCATE TABLE  cohort';\n  EXECUTE IMMEDIATE 'DROP TABLE  cohort';\nEXCEPTION\n  WHEN OTHERS THEN\n    IF SQLCODE != -942 THEN\n      RAISE;\n    END IF;\nEND;")
})


test_that("translateSQL sql server -> Oracle CAST(AS DATE)", {
  sql <- translateSql("CAST('20000101' AS DATE);",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql, "TO_DATE('20000101' , 'yyyymmdd');")
})

test_that("translateSQL sql server -> Oracle concatenate string operator", {
  sql <- translateSql("select distinct cast(cast(YEAR(observation_period_start_date) as varchar(4)) +  '01' + '01' as date) as obs_year;",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql,
               "SELECT  distinct TO_DATE(TO_CHAR(EXTRACT(YEAR FROM observation_period_start_date) ) || '01' || '01' , 'yyyymmdd') as obs_year FROM DUAL;")
})

test_that("translateSQL sql server -> Oracle RIGHT functions", {
  sql <- translateSql("select RIGHT(x,4);",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql, "SELECT  SUBSTR(x,-4) FROM DUAL;")
})

test_that("translateSQL sql server -> Oracle complex query", {
  sql <- translateSql("select CAST(CAST(YEAR(x) AS VARCHAR(12)) + RIGHT('0'+MONTH(x),2) + '01' AS DATE);",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql,
               "SELECT  TO_DATE(TO_CHAR(EXTRACT(YEAR FROM x)  ) || SUBSTR('0' ||EXTRACT(MONTH FROM x),-2) || '01' , 'yyyymmdd') FROM DUAL;")
})

test_that("translateSQL sql server -> Oracle '+' in quote", {
  sql <- translateSql("select '+';", sourceDialect = "sql server", targetDialect = "oracle")$sql
  expect_equal(sql, "SELECT  '+' FROM DUAL;")
})

test_that("translateSQL sql server -> PostgreSQL USE", {
  sql <- translateSql("USE vocabulary;",
                      sourceDialect = "sql server",
                      targetDialect = "postgresql")$sql
  expect_equal(sql, "SET search_path TO  vocabulary;")
})

test_that("translateSQL sql server -> PostgreSQL string concat", {
  sql <- translateSql("'x' + b ( 'x' + b)",
                      sourceDialect = "sql server",
                      targetDialect = "postgresql")$sql
  expect_equal(sql, "'x' || b ( 'x' || b)")
})

test_that("translateSQL sql server -> PostgreSQL string concat", {
  sql <- translateSql("a + ';b'", sourceDialect = "sql server", targetDialect = "postgresql")$sql
  expect_equal(sql, "a || ';b'")
})

test_that("translateSQL sql server -> PostgreSQL string concat", {
  sql <- translateSql("a + ';('", sourceDialect = "sql server", targetDialect = "postgresql")$sql
  expect_equal(sql, "a || ';('")
})


test_that("translateSQL sql server -> PostgreSQL add month", {
  sql <- translateSql("DATEADD(mm,1,date)",
                      sourceDialect = "sql server",
                      targetDialect = "postgresql")$sql
  expect_equal(sql, "CAST((date + 1*INTERVAL'1 month') AS DATE)")
})

test_that("translateSQL sql server -> Oracle multiple inserts in one statement", {
  sql <- translateSql("INSERT INTO my_table (key,value) VALUES (1,0),(2,0),(3,1)",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql,
               "INSERT ALL\nINTO   my_table   (key,value) VALUES (1,0)\n INTO  my_table  (key,value) VALUES (2,0)\n)\n INTO   my_table   (key,value) VALUES (3,1)\nSELECT * FROM dual")
})

test_that("translateSQL sql server -> RedShift VARCHAR(MAX)", {
  sql <- translateSql("VARCHAR(MAX)", sourceDialect = "sql server", targetDialect = "redshift")$sql
  expect_equal(sql, "VARCHAR(MAX)")
})

test_that("translateSQL sql server -> Postgres WITH SELECT", {
  sql <- translateSql("WITH cte1 AS (SELECT a FROM b) SELECT c FROM cte1;",
                      sourceDialect = "sql server",
                      targetDialect = "postgresql")$sql
  expect_equal(sql, "WITH cte1 AS (SELECT a FROM b) SELECT c FROM cte1;")
})

test_that("translateSQL sql server -> Postgres WITH SELECT INTO", {
  sql <- translateSql("WITH cte1 AS (SELECT a FROM b) SELECT c INTO d FROM cte1;",
                      sourceDialect = "sql server",
                      targetDialect = "postgresql")$sql
  expect_equal(sql,
               "CREATE TABLE  d \nAS\nWITH  cte1  AS  (SELECT a FROM b)  SELECT\n c \nFROM\n cte1;")
})

test_that("translateSQL sql server -> Postgres WITH SELECT INTO without FROM", {
  sql <- translateSql("SELECT c INTO d;",
                      sourceDialect = "sql server",
                      targetDialect = "postgresql")$sql
  expect_equal(sql, "CREATE TABLE  d AS\nSELECT\n c ;")
})


test_that("translateSQL sql server -> Postgres WITH INSERT INTO SELECT", {
  sql <- translateSql("WITH cte1 AS (SELECT a FROM b) INSERT INTO c (d int) SELECT e FROM cte1;",
                      sourceDialect = "sql server",
                      targetDialect = "postgresql")$sql
  expect_equal(sql, "WITH cte1 AS (SELECT a FROM b) INSERT INTO c (d int) SELECT e FROM cte1;")
})

test_that("translateSQL sql server -> Oracle WITH SELECT", {
  sql <- translateSql("WITH cte1 AS (SELECT a FROM b) SELECT c FROM cte1;",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql, "WITH cte1 AS (SELECT   a  FROM  b ) SELECT   c  FROM  cte1 ;")
})

test_that("translateSQL sql server -> Oracle WITH SELECT INTO", {
  sql <- translateSql("WITH cte1 AS (SELECT a FROM b) SELECT c INTO d FROM cte1;",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql,
               "CREATE TABLE  d  \nAS\nWITH  cte1  AS  (SELECT   a  FROM  b )  SELECT\n   c \nFROM\n  cte1 ;")
})

test_that("translateSQL sql server -> Oracle WITH INSERT INTO SELECT", {
  sql <- translateSql("WITH cte1 AS (SELECT a FROM b) INSERT INTO c (d int) SELECT e FROM cte1;",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql,
               "INSERT INTO  c (d int)  WITH  cte1  AS  (SELECT   a  FROM  b )  SELECT    e  FROM  cte1 ;")
})

test_that("translateSQL sql server -> PDW WITH SELECT INTO", {
  sql <- translateSql("WITH cte1 AS (SELECT a FROM b) SELECT c INTO d FROM cte1;",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE   d  WITH (DISTRIBUTION = REPLICATE)\nAS\nWITH  cte1  AS  (SELECT a FROM b)  SELECT\n c \nFROM\n cte1;")
})

test_that("translateSQL sql server -> PDW WITH SELECT INTO temp table", {
  sql <- translateSql("WITH cte1 AS (SELECT a FROM b) SELECT c INTO #d FROM cte1;",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE  #d   WITH (LOCATION = USER_DB, DISTRIBUTION =  REPLICATE) AS\nWITH  cte1  AS  (SELECT a FROM b)  SELECT\n c \nFROM\n cte1;")
})

test_that("translateSQL sql server -> PDW create temp table", {
  sql <- translateSql("CREATE TABLE #a (x int);",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE  #a   (x int)\nWITH (LOCATION = USER_DB, DISTRIBUTION =  REPLICATE);")
})

test_that("translateSQL sql server -> PDW create temp table with person_id", {
  sql <- translateSql("CREATE TABLE #a (person_id int);",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE  #a   ( person_id  int)\nWITH (LOCATION = USER_DB, DISTRIBUTION =  HASH(person_id));")
})

test_that("translateSQL sql server -> PDW create temp table with subject_id", {
  sql <- translateSql("CREATE TABLE #a (subject_id int);",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE  #a   ( subject_id  int)\nWITH (LOCATION = USER_DB, DISTRIBUTION =  HASH(subject_id));")
})

test_that("translateSQL sql server -> PDW create temp table with analysis_id", {
  sql <- translateSql("CREATE TABLE #a (analysis_id int);",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE  #a   ( analysis_id  int)\nWITH (LOCATION = USER_DB, DISTRIBUTION =  HASH(analysis_id));")
})

test_that("translateSQL sql server -> PDW create permanent table", {
  sql <- translateSql("CREATE TABLE a (x int);",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE   a  (x int)\nWITH (DISTRIBUTION = REPLICATE);")
})

test_that("translateSQL sql server -> PDW create permanent table with person_id", {
  sql <- translateSql("CREATE TABLE a (person_id int);",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE   a  ( person_id  int)\nWITH (DISTRIBUTION = HASH(person_id));")
})

test_that("translateSQL sql server -> PDW create permanent table with subject_id", {
  sql <- translateSql("CREATE TABLE a (subject_id int);",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE   a  ( subject_id  int)\nWITH (DISTRIBUTION = HASH(subject_id));")
})

test_that("translateSQL sql server -> PDW create permanent table with analysis_id", {
  sql <- translateSql("CREATE TABLE a (analysis_id int);",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE   a  ( analysis_id  int)\nWITH (DISTRIBUTION = HASH(analysis_id));")
})

test_that("translateSQL sql server -> PDW select into permanent table", {
  sql <- translateSql("SELECT a INTO b FROM c WHERE a = 1;",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE   b  WITH (DISTRIBUTION = REPLICATE)\nAS\nSELECT\n a \nFROM\n c WHERE a = 1;")
})

test_that("translateSQL sql server -> PDW select into permanent table with person_id", {
  sql <- translateSql("SELECT a, person_id, b INTO b FROM c WHERE a = 1;",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE   b  WITH (DISTRIBUTION = HASH(person_id))\nAS\nSELECT\n a,  person_id,  b \nFROM\n c WHERE a = 1;")
})

test_that("translateSQL sql server -> PDW select into permanent table with analysis_id", {
  sql <- translateSql("SELECT a, analysis_id, b INTO b FROM c WHERE a = 1;",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "IF XACT_STATE() = 1 COMMIT; CREATE TABLE   b  WITH (DISTRIBUTION = HASH(analysis_id))\nAS\nSELECT\n a,  analysis_id,  b \nFROM\n c WHERE a = 1;")
})

test_that("translateSQL sql server -> Postgres create table if not exists", {
  sql <- translateSql("IF OBJECT_ID('cohort', 'U') IS NULL\n CREATE TABLE cohort\n(cohort_definition_id INT);",
                      sourceDialect = "sql server",
                      targetDialect = "postgresql")$sql
  expect_equal(sql, "CREATE TABLE IF NOT EXISTS  cohort\n (cohort_definition_id INT);")
})

test_that("translateSQL sql server -> Redshift create table if not exists", {
  sql <- translateSql("IF OBJECT_ID('cohort', 'U') IS NULL\n CREATE TABLE cohort\n(cohort_definition_id INT);",
                      sourceDialect = "sql server",
                      targetDialect = "redshift")$sql
  expect_equal(sql, "CREATE TABLE IF NOT EXISTS  cohort\n (cohort_definition_id INT);")
})

test_that("translateSQL sql server -> Oracle create table if not exists", {
  sql <- translateSql("IF OBJECT_ID('cohort', 'U') IS NULL\n CREATE TABLE cohort\n(cohort_definition_id INT);",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql,
               "BEGIN\n  EXECUTE IMMEDIATE 'CREATE TABLE  cohort\n (cohort_definition_id INT)';\nEXCEPTION\n  WHEN OTHERS THEN\n    IF SQLCODE != -955 THEN\n      RAISE;\n    END IF;\nEND;")
})

test_that("translateSQL sql server -> Oracle datefromparts", {
  sql <- translateSql("SELECT DATEFROMPARTS(year,month,day) FROM table",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql,
               "SELECT TO_DATE(TO_CHAR(year,'0000')||'-'||TO_CHAR(month,'00')||'-'||TO_CHAR(day,'00'), 'YYYY-MM-DD') FROM table")
})

test_that("translateSQL sql server -> redshift datefromparts", {
  sql <- translateSql("SELECT DATEFROMPARTS(year,month,day) FROM table",
                      sourceDialect = "sql server",
                      targetDialect = "redshift")$sql
  expect_equal(sql,
               "SELECT TO_DATE(TO_CHAR(year,'0000')||'-'||TO_CHAR(month,'00')||'-'||TO_CHAR(day,'00'), ' YYYY- MM- DD') FROM table")
})


test_that("translateSQL sql server -> Oracle datetime to timestamp", {
  sql <- translateSql("CREATE TABLE x (a DATETIME)",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql, "CREATE TABLE x (a TIMESTAMP)")
})

test_that("translateSQL sql server -> Oracle select random row", {
  sql <- translateSql("SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY RAND()) AS rn FROM table) tmp WHERE rn <= 1",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql,
               "SELECT column FROM (SELECT   column, ROW_NUMBER() OVER (ORDER BY DBMS_RANDOM.VALUE) AS rn  FROM  table ) tmp WHERE rn <= 1")
})

test_that("translateSQL sql server -> Postgres select random row", {
  sql <- translateSql("SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY RAND()) AS rn FROM table) tmp WHERE rn <= 1",
                      sourceDialect = "sql server",
                      targetDialect = "postgresql")$sql
  expect_equal(sql,
               "SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rn FROM table) tmp WHERE rn <= 1")
})

test_that("translateSQL sql server -> Redshift select random row", {
  sql <- translateSql("SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY RAND()) AS rn FROM table) tmp WHERE rn <= 1",
                      sourceDialect = "sql server",
                      targetDialect = "redshift")$sql
  expect_equal(sql,
               "SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rn FROM table) tmp WHERE rn <= 1")
})

test_that("translateSQL sql server -> Oracle select random row using hash", {
  sql <- translateSql("SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY HASHBYTES('MD5',CAST(person_id AS varchar))) tmp WHERE rn <= 1",
                      sourceDialect = "sql server",
                      targetDialect = "oracle")$sql
  expect_equal(sql,
               "SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY DBMS_CRYPTO.HASH(TO_CHAR(person_id ),2)) tmp WHERE rn <= 1")
})

test_that("translateSQL sql server -> Postgres select random row using hash", {
  sql <- translateSql("SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY HASHBYTES('MD5',CAST(person_id AS varchar))) tmp WHERE rn <= 1",
                      sourceDialect = "sql server",
                      targetDialect = "postgresql")$sql
  expect_equal(sql,
               "SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY MD5(CAST(person_id AS varchar))) tmp WHERE rn <= 1")
})

test_that("translateSQL sql server -> Redshift select random row using hash", {
  sql <- translateSql("SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY HASHBYTES('MD5',CAST(person_id AS varchar))) tmp WHERE rn <= 1",
                      sourceDialect = "sql server",
                      targetDialect = "redshift")$sql
  expect_equal(sql,
               "SELECT column FROM (SELECT column, ROW_NUMBER() OVER (ORDER BY MD5(CAST(person_id AS varchar))) tmp WHERE rn <= 1")
})

test_that("translateSQL sql server -> PDW cte with preceding 'with' in quotes", {
  sql <- translateSql("insert into x (a) values ('with'); with cte (a) as(select a from b) select a INTO #c from cte;",
                      sourceDialect = "sql server",
                      targetDialect = "pdw")$sql
  expect_equal(sql,
               "insert into x (a) values ('with'); IF XACT_STATE() = 1 COMMIT; CREATE TABLE  #c   WITH (LOCATION = USER_DB, DISTRIBUTION =  REPLICATE) AS\nWITH  cte (a)  AS (select a from b)  SELECT\n a \nFROM\n cte;")
})

test_that("translateSQL sql server throws error when invalid target is given", {
  expect_error(translateSql("iSELECT * FROM a;", targetDialect = "pwd")$sql)
})


test_that("translateSQL select into issue for pdw", {
  sql <- "SELECT @c1 INTO table FROM @c2 WHERE a = 1;"
  sql <- translateSql(sql, targetDialect = "pdw")$sql
  expect_equal(sql, "IF XACT_STATE() = 1 COMMIT; CREATE TABLE   table  WITH (DISTRIBUTION = REPLICATE)\nAS\nSELECT\n @c1 \nFROM\n @c2 WHERE a = 1;")
})



test_that("translateSQL ## issue on oracle", {
  sql <- "SELECT a FROM c##blah.table;"
  sql <- translateSql(sql, targetDialect = "oracle")$sql
  expect_equal(sql, "SELECT   a  FROM  c##blah.table ;")
})
