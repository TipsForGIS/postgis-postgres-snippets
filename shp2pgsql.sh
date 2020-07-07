shp2pgsql -I -D -s 4326 ./data.shp schema.table_name | psql -U user_name -d db_name
