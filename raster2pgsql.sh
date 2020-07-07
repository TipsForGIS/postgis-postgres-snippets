# 1. running the command from the folder having a tif file

raster2pgsql -I -C -s 4326 -t 30x30 -F -M ./name.tif schema_name.table_name | psql --user=XXX --dbname=XXX --host=XXX --port=XXX

---------------------------------------------------------------------------------------------------------
# 2. running the command from the folder having a tif file with passing the password as a linux variable
# this is practical for Python coding

raster2pgsql -I -C -s 4326 -t 30x30 -F -M ./name.tif schema_name.table_name | PASSWORD=xxx psql --user=XXX --dbname=XXX --host=XXX --port=XXX
