SET SEARCH_PATH TO public;
--SET SEARCH_PATH TO reference_2019;
--SET SEARCH_PATH TO conservative;
--SET SEARCH_PATH TO optimistic_PHEV;
--SET SEARCH_PATH TO optimistic_EV;
--SET SEARCH_PATH TO EV_only;

--/*
drop table if exists optimistic_phev.pm25;

create table optimistic_phev.pm25 as
with shares_ja as (
    SELECT grid.ogc_fid,
    links.link_id,
    ST_LENGTH(ST_Intersection(grid.wkb_geometry, links.geom)) / (links.length * 1000)  as share 
    from reference_2019.results_by_link as links,
    public.inspire_totrut_sweref as grid
    where ST_Intersects(grid.wkb_geometry, links.geom)
),
effects_ja as (
    select shares_ja.ogc_fid,
    sum((results_by_link.pm25_non_exhaust + results_by_link.pm25_exhaust + results_by_link.c_pm25_exhaust) * results_by_link.length * shares_ja.share) as pm25
    from shares_ja
    join reference_2019.results_by_link
    on shares_ja.link_id = results_by_link.link_id
    GROUP BY shares_ja.ogc_fid
),
shares_ua as (
    SELECT grid.ogc_fid,
    links.link_id,
    ST_LENGTH(ST_Intersection(grid.wkb_geometry, links.geom)) / (links.length * 1000)  as share 
    from optimistic_phev.results_by_link as links,
    public.inspire_totrut_sweref as grid
    where ST_Intersects(grid.wkb_geometry, links.geom)
),
effects_ua as (
    select shares_ua.ogc_fid,
    sum((results_by_link.pm25_non_exhaust + results_by_link.pm25_exhaust + results_by_link.c_pm25_exhaust) * results_by_link.length * shares_ua.share) as pm25
    from shares_ua
    join optimistic_phev.results_by_link
    on shares_ua.link_id = results_by_link.link_id
    GROUP BY shares_ua.ogc_fid
),
diff as (
    select
    effects_ua.ogc_fid,
    effects_ja.pm25 as pm25_ja,
    effects_ua.pm25 as pm25_ua,
    effects_ua.pm25 - effects_ja.pm25 as pm25_diff,
    100 * (effects_ua.pm25 - effects_ja.pm25) / effects_ja.pm25 as pm25_change
    from effects_ua
    join effects_ja
    on effects_ua.ogc_fid = effects_ja.ogc_fid
)
select
    diff.*,
    inspire_totrut_sweref.wkb_geometry
from diff
join public.inspire_totrut_sweref
on diff.ogc_fid = inspire_totrut_sweref.ogc_fid;

--*/
/*
--SET SEARCH_PATH TO public;
SET SEARCH_PATH TO reference_2019;
--SET SEARCH_PATH TO conservative;
--SET SEARCH_PATH TO optimistic_PHEV;
--SET SEARCH_PATH TO optimistic_EV;
--SET SEARCH_PATH TO EV_only;


DROP TABLE IF EXISTS test;
CREATE TABLE test AS
SELECT
    --grid.ogc_fid,
    --links.link_id,
    ST_Intersection(inspire_totrut_sweref.wkb_geometry, results_by_link.geom)
FROM reference_2019.results_by_link,
     public.inspire_totrut_sweref
where ST_Intersects(inspire_totrut_sweref.wkb_geometry, results_by_link.geom);
*/
/*
DROP TABLE IF EXISTS test2;
CREATE TABLE test2 as
    SELECT grid.ogc_fid,
    links.link_id,
    ST_LENGTH(ST_Intersection(grid.wkb_geometry, links.geom)) / (links.length * 1000)  as share 
    from reference_2019.results_by_link as links,
    public.inspire_totrut_sweref as grid
    where ST_Intersects(grid.wkb_geometry, links.geom);

DROP TABLE IF EXISTS test, test2;
*/
/*
DROP TABLE IF EXISTS grid;
CREATE TABLE grid AS
select  ogc_fid
,rut_id
,ST_ROTATE(wkb_geometry, 3) AS wkb_geometry
from public.inspire_totrut_sweref;

SELECT * FROM grid LIMIT 1000;
*/