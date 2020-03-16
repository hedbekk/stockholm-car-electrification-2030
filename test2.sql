--SELECT COUNT(*) AS "Number of rows in link_movement"FROM scenario_1_2_nvdb.link_movement;
/*
DROP FUNCTION IF EXISTS urbrurfunc;
CREATE OR REPLACE FUNCTION urbrurfunc(wkb_geometry GEOMETRY) RETURNS VARCHAR AS $$
        BEGIN
                IF wkb_geometry IS NOT NULL THEN 
                        RETURN 'urban';
                ELSE
                        RETURN 'rural';
                END IF;        
        END;
$$ LANGUAGE plpgsql;

--DROP FUNCTION testfunc(capacity FLOAT, flow BIGINT);
/*CREATE OR REPLACE FUNCTION testfunc(capacity FLOAT, flow BIGINT) RETURNS VARCHAR AS $$
DECLARE
        flow_capacity_ratio float := flow/capacity;        
        BEGIN
                IF flow_capacity_ratio <= 0.6 THEN
                        RETURN 'freeflow';
                ELSIF flow_capacity_ratio <= 0.9 THEN
                        RETURN 'heavy';
                ELSIF flow_capacity_ratio <= 1 THEN
                        RETURN 'saturated';
                ELSIF flow_capacity_ratio <= 1.2 THEN
                        RETURN 'stop_go';
                ELSE
                        RETURN 'stop_go_2';
                END IF;        
        END;
$$ LANGUAGE plpgsql;


CREATE INDEX IF NOT EXISTS link_movement_vehicle_id_idx
ON scenario_1_2_nvdb.link_movement(vehicle_id);

CREATE INDEX IF NOT EXISTS link_movement_start_time_idx
ON scenario_1_2_nvdb.link_movement(start_time);

CREATE INDEX IF NOT EXISTS link_movement_end_time_idx
ON scenario_1_2_nvdb.link_movement(end_time);

CREATE INDEX IF NOT EXISTS link_movement_link_id_idx
ON scenario_1_2_nvdb.link_movement(link_id);

CREATE INDEX IF NOT EXISTS links_length_idx
ON scenario_1_2_nvdb.links(length);

CREATE INDEX IF NOT EXISTS links_capacity_idx
ON scenario_1_2_nvdb.links(capacity);

CREATE INDEX IF NOT EXISTS links_freespeed_idx
ON scenario_1_2_nvdb.links(freespeed);

CREATE INDEX IF NOT EXISTS car_flow_by_hour_flow_idx
ON scenario_1_2_nvdb.car_flow_by_hour(flow);

CREATE INDEX IF NOT EXISTS car_flow_by_hour_idx
ON scenario_1_2_nvdb.car_flow_by_hour(hour);

CREATE INDEX IF NOT EXISTS links_link_id_idx
ON scenario_1_2_nvdb.links(link_id);*/


DROP TABLE IF EXISTS temptable;
CREATE TABLE temptable AS
SELECT
        link_movement.vehicle_id,
        link_movement.link_id,
                --DATE_TRUNC('hour', (start_time + (end_time - start_time)/2)),
                --end_time,
                --pg_typeof(end_time),
        link_movement.start_time,
        EXTRACT(SECOND FROM (end_time - start_time)) AS duration,
        links.length,
        links.capacity,
        car_flow_by_hour.flow,
        3.6*length/(EXTRACT(SECOND FROM (end_time - start_time))) AS actual_speed,
        (SELECT urbrurfunc(wkb_geometry => public.to2018_swe99tm.wkb_geometry)) AS area, --urban or rural
        'TBD' AS road_type, -- Motorway-Nat., Motorway-City, Semi-Motorway, Primary-nat. non-motorway, Primary-city non-motorway, Distributor/Secondary, Distributor/Secondary(sinuous), Local/Collector, Local/Collector(sinuous), Access-residential
        CAST(links.freespeed*3.6 AS INTEGER) AS speed_limit,
        (SELECT testfunc(capacity => links.capacity, flow => car_flow_by_hour.flow)) AS level_of_service
FROM scenario_1_2_nvdb.link_movement AS link_movement FULL JOIN scenario_1_2_nvdb.links AS links
        ON link_movement.link_id = links.link_id
LEFT JOIN scenario_1_2_nvdb.car_flow_by_hour AS car_flow_by_hour
        ON car_flow_by_hour.hour = DATE_TRUNC('hour', start_time) AND car_flow_by_hour.link_id = link_movement.link_id
LEFT JOIN public.to2018_swe99tm
        ON links.geom && public.to2018_swe99tm.wkb_geometry        
WHERE EXTRACT(SECOND FROM (end_time - start_time)) > 0 /*ORDER BY link_id, start_time*/ LIMIT 1000;

--SELECT COUNT(DISTINCT vehicle_id) AS vechicle_id, COUNT(DISTINCT link_id) AS link_id FROM temptable;
SELECT * FROM temptable;

/*DROP INDEX IF EXISTS link_movement_vehicle_id_idx;
DROP INDEX IF EXISTS link_movement_start_time_idx;
DROP INDEX IF EXISTS link_movement_end_time_idx;
DROP INDEX IF EXISTS link_movement_link_id_idx;
DROP INDEX IF EXISTS links_length_idx;
DROP INDEX IF EXISTS links_capacity_idx;
DROP INDEX IF EXISTS links_freespeed_idx;
DROP INDEX IF EXISTS car_flow_by_hour_flow_idx;
DROP INDEX IF EXISTS car_flow_by_hour_idx
DROP INDEX IF EXISTS links_link_id_idx;*/




