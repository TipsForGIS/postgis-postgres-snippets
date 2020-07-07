-- 1. Get the physical size of a specific table
SELECT pg_size_pretty(pg_total_relation_size('schema_name.table_name'));

------------------------------------------------------------------------
-- 2. Get the physical size of a specifc schema
SELECT pg_size_pretty(SUM(pg_relation_size(concat(schemaname,'.',tablename)))) AS alias
FROM pg_tables
WHERE schemaname='public';

------------------------------------------------------------------------
-- 3. Create drop table statements for multiple tables with the same prefix. 
-- You need to export the result in CSV to copy it back into PGADMIN for instance
SELECT 
CONCAT( 'DROP TABLE IF EXISTS', table_schema ,'.', table_name , ';' ) AS drop_statement 
FROM information_schema.tables
WHERE table_schema = 'public' and table_name like 'my_table_%'
order by table_name;

------------------------------------------------------------------------
-- 4. Check if specific index exists in a specific table     
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'bldgs' AND indexname ILIKE '%geom%';

------------------------------------------------------------------------
-- 5. Check table names on a specific schema
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'schema_name' AND table_name ilike 'bldg%';
--OR
SELECT schemaname, tablename
FROM pg_catalog.pg_tables 
WHERE schemaname = 'schema_name' and tablename ilike 'bldg%';

------------------------------------------------------------------------
-- 6. get columns names for a specific table
SELECT column_name 
FROM information_schema.columns
WHERE table_schema = 'public' and table_name = 'county_albers';

------------------------------------------------------------------------
-- 7. get the total number of columns in a table
SELECT COUNT(*) 
FROM information_schema.columns 
WHERE table_schema = 'XXX' AND table_name='YYY';


------------------------------------------------------------------------
-- 8. generate DROP TABLE statement for all tables with specific prefix

SELECT 'DROP TABLE schema.' || tablename || ';'
FROM pg_tables
WHERE schemaname = 'schema'
AND tablename ILIKE 'bldg_%';

