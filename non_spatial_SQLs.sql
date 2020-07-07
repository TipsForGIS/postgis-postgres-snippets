--1. Updates a column value based on the maximum value from two other columns
update table_name
set new_column = 
case when col1 > col2 then 'some value1'
	 when col2 > col1 then 'some value2'
	 else 'N/A'
end
--------------------------------------------------------------------------------------------------

-- 2. Alters a data type of a column in a table

ALTER TABLE schema_name.table_name
ALTER COLUMN column_name TYPE varchar(15);

------------------------------------------------------------------------
-- 3. Alters a table by dropping a column

ALTER TABLE schema_name.table_name
DROP COLUMN column_name;

------------------------------------------------------------------------
-- 4. Alters a table by adding a new column

ALTER TABLE schema_name.table_name
ADD COLUMN column_name numeric;
    
------------------------------------------------------------------------
-- 5. Selects the count of a column for each of its values 

SELECT col_name, COUNT(col_name)
FROM schema_name.table_name
GROUP BY col_name
HAVING COUNT(col_name) > 1
ORDER BY COUNT(col_name) DESC;

------------------------------------------------------------------------
-- 6. Selects rows from table a where there are no matches from table b "missing foreign keys"

SELECT a.col_name
FROM schema_name.table_name_1 as a
LEFT JOIN schema_name.table_name_2 as b 
ON (a.col_name = b.col_name)
WHERE b.col_name IS NULL;

------------------------------------------------------------------------
-- 7. Selects names with distinct different ids 

SELECT a.user_id, b.user_id, a.name
FROM users as a 
JOIN users as b
ON (a.name = b.name and a.user_id < b.user_id);

------------------------------------------------------------------------
-- 8. Use a with clause instead of an inner query, this option will speed up the query because the with clause
-- creates a temp view "maybe materialized" once instead of querying on every call if it an inner query

WITH res as (SELECT id,name FROM table_name WHERE col3 IN ('a','b','c'))
SELECT id, name
FROM res
JOIN table2
on(....)

------------------------------------------------------------------------
-- 9. Add a new primary and serial column to a table

ALTER TABLE schema_name.table_name ADD COLUMN new_id SERIAL PRIMARY KEY;


------------------------------------------------------------------------
-- 10. Get the values not in an "IN" array on a WHERE col IN ('val1','val2','val3')
-- UNNEST will create temporary rows of the values in the array

SELECT UNNEST(ARRAY['val1','val2','val3']) as name
EXCEPT
SELECT name
FROM schema_name.table_name
WHERE name IN ('val1','val2','val3');

