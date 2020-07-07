--1. Merges multilinestring into one line string

SELECT st_asgeojson(st_union(ST_LineMerge(the_geom)))
from table_name
where column_name ilike ‘%main st%’;
--------------------------------------------------------------------------------------------------

--2. Selects intersected points with a specific polygon

select pts.cartodb_id, pts.the_geom_webmercator
from point_table as pts
join polygon_table as polys
on (st_intersects(pts.the_geom, polys.the_geom))
where polys.name ilike '%fairfax%';
--------------------------------------------------------------------------------------------------

--3. Checks if two geometries within the same table intersect

select st_intersects(l1.the_geom,l2.the_geom)
from line_table as l1
join line_table as l2
on (l1.name ilike '%1st st%' and l2.name ilike '%main st%');
--------------------------------------------------------------------------------------------------

--4. Spatial join: After running this query, you can export the result as a new postGIS table containing the spatial join

SELECT pnts.*, polys.name
FROM point_table as pnts
JOIN polygon_table as polys
ON (st_intersects(pnts.the_geom, pnts.the_geom));
--------------------------------------------------------------------------------------------------

--5. Spatial join: first, you create a new column in the points table, then you update its value based on the intersection

ALTER TABLE point_table ADD COLUMN value_from_poly_column varchar(50);
update point_table
set value_from_poly_column = 
(
  SELECT con.name
  FROM point_table as pnts, polygon_table as polys
  where st_intersects(pnts.the_geom,polys.the_geom)
  and point_table.the_geom = pnts.the_geom
);
--------------------------------------------------------------------------------------------------

--6. Calculates how many points intersects with each polygon from an overlaid polygon table
SELECT polys.name, count(pnts.*)
FROM point_table as pnts
join polygon_table as polys
on (st_intersects(pnts.the_geom, polys.the_geom))
group by polys.name
order by count desc;
--------------------------------------------------------------------------------------------------

--7. Alters table to add a geometry column of type point

alter table table_name add column column_name geometry(Point);

--------------------------------------------------------------------------------------------------

--8. Alters table to add a decimal column for longitude values

alter table table_name add column column_name decimal(10,7);

--------------------------------------------------------------------------------------------------
--9. Updates the values of a decimal-type-column (decimal(10,7)) with the x/longitude value of the_geom

update table_name set column_name = st_x(st_centroid(the_geom));

--------------------------------------------------------------------------------------------------
--10. Updates the values of a varchar-type-column with the bounding box of the_geom

update table_name set column_name = box2d(the_geom); 

--------------------------------------------------------------------------------------------------
--11. Calculates the areas of envelopes or bounding boxes using xMin, yMin, xMax, and yMax values in an array

SELECT ST_Area(ST_MakeEnvelope(col_name[1],col_name[2],col_name[3],col_name[4],4326)) as area
FROM schema.table;

--------------------------------------------------------------------------------------------------
--12. Concatenate degree, minutes, seconds, and directions columns of lats and lngs. Notice two case staements to return two columns
select
	case
		when lon_dir = 'W'
		then round(((lon_deg + lon_min/60 + lon_sec/3600)*-1)::numeric,7)
		when lon_dir = 'E'
		then round((lon_deg + lon_min/60 + lon_sec/3600)::numeric,7)
		else -999::numeric
	end as lng,
	case
		when lat_dir = 'N'
		then round((lat_deg + lat_min/60 + lat_sec/3600)::numeric,7)
		when lat_dir = 'S'
		then round(((lat_deg + lat_min/60 + lat_sec/3600)*-1)::numeric,7)
		else -999::numeric
	end as lat
from table_name;

--------------------------------------------------------------------------------------------------
--13. Create 1000 random point based on a polygon extent. ST_Dump will split the points in rows 
SELECT (ST_Dump(ST_GeneratePoints(geom,1000))).geom as geom
FROM schema.table;

--------------------------------------------------------------------------------------------------
--14. Change the projection of the geom column

ALTER TABLE schema_name.table_name
ALTER COLUMN geom TYPE geometry(Polygon, 42303)
USING ST_Transform(ST_SetSRID(geom, st_srid(geom)), 42303);

--------------------------------------------------------------------------------------------------
--15. Select points that DO NOT INTERSECT with polys using LEFT JOIN instead of ST_Disjoint
-- since ST_Disjoint does not use a spatial index
SELECT pnts.*
FROM schema.pnts_table as pnts 
LEFT JOIN schema.polys_table as polys
ON (ST_Intersects(polys.geom, pts.geom))
WHERE polys.id IS NULL;

--------------------------------------------------------------------------------------------------
--16. address in building in parcel within a specific census tract

with trct_addrs as
	(select a.id as addr_id, a.geom as ageom
	from schema.addr_table as a
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(a.geom,t.geom))),
trct_bldgs as
	(select b.id as bldg_id, b.geom as bgeom
	from schema.bldg_table as b
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(b.geom,t.geom))),
trct_prcls as
	(select p.id as prcl_id, p.geom as pgeom
	from schema.prcl_table as p
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(p.geom,t.geom))) 
select addr_id,bldg_id,prcl_id 
from trct_addrs,trct_bldgs,trct_prcls 
where st_intersects(ageom,trct_bgeom) 
and st_intersects(st_centroid(bgeom),pgeom)
order by addr_id,bldg_id,prcl_id;

--------------------------------------------------------------------------------------------------
--17. address not in building but building in parcel within a specific census tract

with trct_addrs as
	(select a.id as addr_id, a.geom as ageom
	from schema.addr_table as a
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(a.geom,t.geom))),
trct_bldgs as
	(select b.id as bldg_id, b.geom as bgeom
	from schema.bldg_table as b
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(b.geom,t.geom))),
trct_prcls as
	(select p.id as prcl_id, p.geom as pgeom
	from schema.prcl_table as p
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(p.geom,t.geom))),
prcl_with_one_bldg as(
	with prcl_bldg_grpby as
		(select prcl_id, pgeom, count(bldg_id)
		from trct_prcls,trct_bldgs
		where st_contains(pgeom,bgeom)
		group by prcl_id, pgeom
		having count(bldg_id) = 1)
	select bldg_id, prcl_id, pgeom
	from trct_bldgs
	join prcl_bldg_grpby
	on (st_within(bgeom,pgeom))),
addr_not_in_bldg as
	(select addr_key, ageom
 	from trct_addrs
	left join trct_bldgs
	on(st_intersects(ageom,bgeom))
	where bldg_id is null)											 
select DISTINCT ON(addr_id) addr_id,bldg_id,prcl_id
from addr_not_in_bldg, prcl_with_one_bldg
where st_intersects(pgeom,ageom)
order by addr_id,bldg_id,prcl_id;

--------------------------------------------------------------------------------------------------
--18. address not in building but multi-building in parcel within a specific census tract

with trct_addrs as
	(select a.id as addr_id, a.geom as ageom
	from schema.addr_table as a
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(a.geom,t.geom))),
trct_bldgs as
	(select b.id as bldg_id, b.geom as bgeom
	from schema.bldg_table as b
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(b.geom,t.geom))),
trct_prcls as
	(select p.id as prcl_id, p.geom as pgeom
	from schema.prcl_table as p
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(p.geom,t.geom))),
addr_in_prcl_multi_bldg as
	   (with prcl_bldg_grpby as
			(select prcl_id, pgeom, count(bldg_id)
			from trct_prcls,trct_bldgs
			where st_contains(pgeom,bgeom)
			group by prcl_id, pgeom
			having count(bldg_id) > 1),
		addr_not_in_bldg as
			(select addr_id, ageom
			from trct_addrs
			left join trct_bldgs
			on(st_intersects(ageom,bgeom))
			where bldg_id is null)
		select distinct on(addr_id) addr_id, prcl_id, ageom
		from prcl_bldg_grpby, addr_not_in_bldg
		where st_intersects(ageom,pgeom))			
select distinct on (addr_id) addr_id, bldg_id, prcl_id
from addr_in_prcl_multi_bldg
join trct_bldgs
on (st_dwithin(ageom,bgeom,100))
order by addr_id, st_distance(ageom,bgeom);

--------------------------------------------------------------------------------------------------
--19. address close to parcel with one building in parcel within a specific census tract

with trct_addrs as
	(select a.id as addr_id, a.geom as ageom
	from schema.addr_table as a
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(a.geom,t.geom))),
trct_bldgs as
	(select b.id as bldg_id, b.geom as bgeom
	from schema.bldg_table as b
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(b.geom,t.geom))),
trct_prcls as
	(select p.id as prcl_id, p.geom as pgeom
	from schema.prcl_table as p
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(p.geom,t.geom))),
one_bldg_in_prcl as
	(with prcl_bldg_grpby as
	 	(select prcl_id, pgeom, count(bldg_id)
		from trct_prcls,trct_bldgs
		where st_contains(pgeom,bgeom)
		group by prcl_id, pgeom
		having count(bldg_id) = 1)
	select bldg_id, prcl_id, pgeom
	from trct_bldgs
	join prcl_bldg_grpby
	on (st_within(bgeom,pgeom))),
addr_not_in_prcl as
	(select addr_id, ageom
 	from trct_addrs
	left join trct_prcls
	on(st_intersects(ageom,pgeom))
	where prcl_id is null)											 
select DISTINCT ON(addr_id) addr_id,bldg_id,prcl_id
from addr_not_in_prcl
join one_bldg_in_prcl
on (st_dwithin(ageom,pgeom,100))
order by addr_id, st_distance(ageom,pgeom);

--------------------------------------------------------------------------------------------------
--20. address close to parcel with multi-building in parcel within a specific census tract

with trct_addrs as
	(select a.id as addr_id, a.geom as ageom
	from schema.addr_table as a
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(a.geom,t.geom))),
trct_bldgs as
	(select b.id as bldg_id, b.geom as bgeom
	from schema.bldg_table as b
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(b.geom,t.geom))),
trct_prcls as
	(select p.id as prcl_id, p.geom as pgeom
	from schema.prcl_table as p
	join schema.trct_table as t
	on(t.tract_id = 'XYZ' and st_intersects(p.geom,t.geom))),
addr_in_prcl_multi_bldg as
	   (with prcl_bldg_grpby as
			(select prcl_id, pgeom, count(bldg_id)
			from trct_prcls,trct_bldgs
			where st_contains(pgeom,bgeom)
			group by prcl_id, pgeom
			having count(bldg_id) > 1),
		addr_not_in_prcl as 
			(select addr_id, ageom
			from trct_addrs
			left join trct_prcls
			on(st_intersects(ageom,pgeom))
			where prcl_id is null)
		select distinct on(addr_id) addr_id, prcl_id, ageom
		from prcl_bldg_grpby, addr_not_in_prcl
		where st_dwithin(ageom,pgeom,100)
		order by addr_id, st_distance(ageom,pgeom))
		--where st_intersects(ageom,pgeom))			
select distinct on (addr_id) addr_id, bldg_id, prcl_id
from addr_in_prcl_multi_bldg
join trct_bldgs
on (st_dwithin(ageom,bgeom,100))
order by addr_id, st_distance(ageom,bgeom);

--------------------------------------------------------------------------------------------------
--21. recursively walk a network

WITH RECURSIVE walk_network(id, segment) AS (
  SELECT id, segment 
    FROM schema.paul_ramsey_network 
    WHERE id = 6
  UNION ALL
  SELECT n.id, n.segment
    FROM schema.paul_ramsey_network n, walk_network w
    WHERE ST_DWithin(
      ST_EndPoint(w.segment),
      ST_StartPoint(n.segment),0.01)
)
SELECT id
FROM walk_network;


--------------------------------------------------------------------------------------------------
--22. get raster pixel values where intersected with a given point vector table

select r.rid, st_value(r.rast,p.geom) as raster_val
from schema.raster_table as r
join schema.point_table as p
on (st_intersects(r.rast,p.geom));


--------------------------------------------------------------------------------------------------
--23. get reasons of geom invalidity in a table 

select gid, ST_IsValidReason(geom)
from schema.table
where st_isvalid(geom) is false;

--------------------------------------------------------------------------------------------------
--24. validate invalid geoms by either st_makevalid or st_buffer by 0

UPDATE schema.table
SET geom = st_makevalid(geom)
-- geom = st_buffer(geom,0)
WHERE st_isvalid(geom) is false;
