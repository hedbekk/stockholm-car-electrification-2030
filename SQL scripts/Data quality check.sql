/*DROP TABLE IF EXISTS hour;
CREATE TABLE hour(hour_text VARCHAR, hour_time TIME);

INSERT INTO hour(hour_text, hour_time)
VALUES
    ('h_0', '00:00:00'),
    ('h_1', '01:00:00'),
    ('h_2', '02:00:00'),
    ('h_3', '03:00:00'),
    ('h_4', '04:00:00'),
    ('h_5', '05:00:00'),
    ('h_6', '06:00:00'),
    ('h_7', '07:00:00'),
    ('h_8', '08:00:00'),
    ('h_9', '09:00:00'),
    ('h_10', '10:00:00'),
    ('h_11', '11:00:00'),
    ('h_12', '12:00:00'),
    ('h_13', '13:00:00'),
    ('h_14', '14:00:00'),
    ('h_15', '15:00:00'),
    ('h_16', '16:00:00'),
    ('h_17', '17:00:00'),
    ('h_18', '18:00:00'),
    ('h_19', '19:00:00'),
    ('h_20', '20:00:00'),
    ('h_21', '21:00:00'),
    ('h_22', '22:00:00'),
    ('h_23', '23:00:00');

--SELECT * FROM hour;


DROP FUNCTION IF EXISTS los_to_number(level_of_service VARCHAR); -- Function is used to convert level of service flowclasses written in text to numbers (1, 2, 3, 4 or 5)
CREATE OR REPLACE FUNCTION los_to_number(level_of_service VARCHAR) RETURNS FLOAT AS $$
    BEGIN
        IF level_of_service = 'Freeflow' THEN
            RETURN 1;
        ELSEIF level_of_service = 'Heavy' THEN
            RETURN 2;
        ELSEIF level_of_service = 'Satur.' THEN
            RETURN 3;
        ELSEIF level_of_service = 'St+Go' THEN
            RETURN 4;
        ELSEIF level_of_service = 'St+Go2' THEN
            RETURN 5;
        ELSE
            RETURN NULL;
        END IF;        
    END;
$$ LANGUAGE plpgsql;

*/
--------------------------------------- Scenario specific calculations --------------------------------------------------------------------------------------


--SET SEARCH_PATH TO reference_2019;
--SET SEARCH_PATH TO conservative;
--SET SEARCH_PATH TO optimistic_PHEV;
--SET SEARCH_PATH TO optimistic_EV;
--SET SEARCH_PATH TO EV_only;

/*
DROP TABLE IF EXISTS statistics_by_hour; --Table showing cars driving and the average level of service at exactly 1:00, 2:00, 3:00, 4:00, 5:00...
CREATE TABLE statistics_by_hour AS
WITH driving_at_the_hour AS( --Table of "link_movements" at exactly 1:00, 2:00, 3:00, 4:00, 5:00...
    SELECT
        hour_text,
        hour_time,
        start_time,
        end_time,
        duration,
        level_of_service,
        public.los_to_number(level_of_service => level_of_service)
    FROM public.hour
    LEFT JOIN results
        ON CAST(results.end_time AS TIME) >= hour.hour_time
        AND CAST(results.start_time AS TIME) < hour.hour_time
    ORDER BY hour_time)
SELECT 
    hour_text,
    hour_time,
    COUNT(hour_text)*10 AS car_count,
    AVG(los_to_number) AS level_of_service
FROM driving_at_the_hour
GROUP BY hour_text, hour_time
ORDER BY hour_time;

SELECT * FROM statistics_by_hour;


DROP TABLE IF EXISTS statistics_by_hour_and_link;  
CREATE TABLE statistics_by_hour_and_link AS  --The car flow by hour and average level of service by hour for links that have traffic
SELECT 
    CAST(date_trunc('hour', start_time) AS TIME) AS hour,
    link_id,
    length,
    COUNT(vehicle_id)*10 AS flow,
    capacity,
    AVG(public.los_to_number(level_of_service => level_of_service)) AS level_of_service, --Average level of service score, between 1 and 5, where 1 represents "Freeflow" and 5 represents "St+Go2"
    geom
FROM link_movement_links
GROUP BY hour, link_id, length, geom, capacity
ORDER BY link_id, hour;

CREATE INDEX IF NOT EXISTS statistics_by_hour_and_link_link_id_idx ON statistics_by_hour_and_link(link_id);
CREATE INDEX IF NOT EXISTS statistics_by_hour_and_link_hour_idx ON statistics_by_hour_and_link(hour);

--SELECT * FROM statistics_by_hour_and_link LIMIT 1000;


DROP TABLE IF EXISTS car_flow_by_hour_and_link; --The car flow by hour for all links (including links with no traffic)
CREATE TABLE car_flow_by_hour_and_link AS
WITH
    car_flow_at_0 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '00:00:00'),
    car_flow_at_1 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '01:00:00'),
    car_flow_at_2 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '02:00:00'),
    car_flow_at_3 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '03:00:00'),
    car_flow_at_4 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '04:00:00'),
    car_flow_at_5 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '05:00:00'),
    car_flow_at_6 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '06:00:00'),
    car_flow_at_7 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '07:00:00'),
    car_flow_at_8 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '08:00:00'),
    car_flow_at_9 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '09:00:00'),
    car_flow_at_10 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '10:00:00'),
    car_flow_at_11 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '11:00:00'),
    car_flow_at_12 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '12:00:00'),
    car_flow_at_13 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '13:00:00'),
    car_flow_at_14 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '14:00:00'),
    car_flow_at_15 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '15:00:00'),
    car_flow_at_16 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '16:00:00'),
    car_flow_at_17 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '17:00:00'),
    car_flow_at_18 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '18:00:00'),
    car_flow_at_19 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '19:00:00'),
    car_flow_at_20 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '20:00:00'),
    car_flow_at_21 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '21:00:00'),
    car_flow_at_22 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '22:00:00'),
    car_flow_at_23 AS (SELECT link_id, flow FROM statistics_by_hour_and_link WHERE hour = '23:00:00')
SELECT
    links.link_id,
    links.length,
    links.capacity,
    COALESCE(car_flow_at_0.flow, 0) AS h_0,
    COALESCE(car_flow_at_1.flow, 0) AS h_1,
    COALESCE(car_flow_at_2.flow, 0) AS h_2,
    COALESCE(car_flow_at_3.flow, 0) AS h_3,
    COALESCE(car_flow_at_4.flow, 0) AS h_4,
    COALESCE(car_flow_at_5.flow, 0) AS h_5,
    COALESCE(car_flow_at_6.flow, 0) AS h_6,
    COALESCE(car_flow_at_7.flow, 0) AS h_7,
    COALESCE(car_flow_at_8.flow, 0) AS h_8,
    COALESCE(car_flow_at_9.flow, 0) AS h_9,
    COALESCE(car_flow_at_10.flow, 0) AS h_10,
    COALESCE(car_flow_at_11.flow, 0) AS h_11,
    COALESCE(car_flow_at_12.flow, 0) AS h_12,
    COALESCE(car_flow_at_13.flow, 0) AS h_13,
    COALESCE(car_flow_at_14.flow, 0) AS h_14,
    COALESCE(car_flow_at_15.flow, 0) AS h_15,
    COALESCE(car_flow_at_16.flow, 0) AS h_16,
    COALESCE(car_flow_at_17.flow, 0) AS h_17,
    COALESCE(car_flow_at_18.flow, 0) AS h_18,
    COALESCE(car_flow_at_19.flow, 0) AS h_19,
    COALESCE(car_flow_at_20.flow, 0) AS h_20,
    COALESCE(car_flow_at_21.flow, 0) AS h_21,
    COALESCE(car_flow_at_22.flow, 0) AS h_22,
    COALESCE(car_flow_at_23.flow, 0) AS h_23,
    links.geom
FROM public.links AS links
    LEFT JOIN car_flow_at_0 ON links.link_id = car_flow_at_0.link_id
    LEFT JOIN car_flow_at_1 ON links.link_id = car_flow_at_1.link_id
    LEFT JOIN car_flow_at_2 ON links.link_id = car_flow_at_2.link_id
    LEFT JOIN car_flow_at_3 ON links.link_id = car_flow_at_3.link_id
    LEFT JOIN car_flow_at_4 ON links.link_id = car_flow_at_4.link_id
    LEFT JOIN car_flow_at_5 ON links.link_id = car_flow_at_5.link_id
    LEFT JOIN car_flow_at_6 ON links.link_id = car_flow_at_6.link_id
    LEFT JOIN car_flow_at_7 ON links.link_id = car_flow_at_7.link_id
    LEFT JOIN car_flow_at_8 ON links.link_id = car_flow_at_8.link_id
    LEFT JOIN car_flow_at_9 ON links.link_id = car_flow_at_9.link_id
    LEFT JOIN car_flow_at_10 ON links.link_id = car_flow_at_10.link_id
    LEFT JOIN car_flow_at_11 ON links.link_id = car_flow_at_11.link_id
    LEFT JOIN car_flow_at_12 ON links.link_id = car_flow_at_12.link_id
    LEFT JOIN car_flow_at_13 ON links.link_id = car_flow_at_13.link_id
    LEFT JOIN car_flow_at_14 ON links.link_id = car_flow_at_14.link_id
    LEFT JOIN car_flow_at_15 ON links.link_id = car_flow_at_15.link_id
    LEFT JOIN car_flow_at_16 ON links.link_id = car_flow_at_16.link_id
    LEFT JOIN car_flow_at_17 ON links.link_id = car_flow_at_17.link_id
    LEFT JOIN car_flow_at_18 ON links.link_id = car_flow_at_18.link_id
    LEFT JOIN car_flow_at_19 ON links.link_id = car_flow_at_19.link_id
    LEFT JOIN car_flow_at_20 ON links.link_id = car_flow_at_20.link_id
    LEFT JOIN car_flow_at_21 ON links.link_id = car_flow_at_21.link_id
    LEFT JOIN car_flow_at_22 ON links.link_id = car_flow_at_22.link_id
    LEFT JOIN car_flow_at_23 ON links.link_id = car_flow_at_23.link_id
ORDER BY link_id; --Total execution time: 00:00:02.879

--SELECT * FROM car_flow_by_hour_and_link LIMIT 1000;


DROP TABLE IF EXISTS capacity_test; --Used to check the relationship between the capacity and car flow (between 16 and 17)
CREATE TABLE capacity_test AS
SELECT
    CAST(h_17 AS FLOAT)/capacity*100 AS capacity_utilization,
    link_id,
    geom
FROM car_flow_by_hour_and_link
WHERE CAST(h_17 AS FLOAT)/capacity>0.5
ORDER BY CAST(h_17 AS FLOAT)/capacity DESC;

SELECT * FROM capacity_test;


DROP TABLE IF EXISTS level_of_service_stats;
CREATE TABLE level_of_service_stats AS
SELECT  --Table showing the average and total amount of time cars spend in each level of service flowclass
    level_of_service,
    COUNT(level_of_service) AS los_count,
    AVG(duration) AS avg_duration, --Unit: seconds
    SUM(duration)/3600/24 AS total_duration, --Unit: days
    SUM(length) AS trip_distance, --Unit: km
    AVG(length) AS avg_distance --Unit: km
FROM results
GROUP BY level_of_service
ORDER BY CASE WHEN level_of_service = 'Freeflow' THEN 1
              WHEN level_of_service = 'Heavy' THEN 2
              WHEN level_of_service = 'Satur.' THEN 3
              WHEN level_of_service = 'St+Go' THEN 4
              WHEN level_of_service = 'St+Go2' THEN 5
              END;

SELECT * FROM level_of_service_stats;


DROP TABLE IF EXISTS count_mov_type;
CREATE TABLE count_mov_type AS(
    SELECT 
        CAST(vehicle_id AS INTEGER),
        mov_type,
        COUNT(mov_type)
FROM link_movement
GROUP BY vehicle_id, mov_type);

--SELECT
--    (SELECT COUNT(*) FROM count_mov_type WHERE mov_type = 'enter') AS enter,
--    (SELECT COUNT(*) FROM count_mov_type WHERE mov_type = 'enroute') AS enroute,
--    (SELECT COUNT(*) FROM count_mov_type WHERE mov_type = 'leave') AS leave;


DROP TABLE IF EXISTS enter_enroute_leave; --Returns vehicle_ids for cars in link_movements for which mov_type = 'enter' > mov_type = 'leave'
CREATE TABLE enter_enroute_leave AS
WITH
    enter AS (SELECT * FROM count_mov_type WHERE mov_type = 'enter'),
    enroute AS (SELECT * FROM count_mov_type WHERE mov_type = 'enroute'),
    leave AS (SELECT * FROM count_mov_type WHERE mov_type = 'leave')
SELECT
    COALESCE(enroute.vehicle_id, enter.vehicle_id, leave.vehicle_id) AS vehicle_id,
    COALESCE(enter.count, 0) AS enter_count,
    COALESCE(enroute.count, 0) AS enroute_count,
    COALESCE(leave.count, 0) AS leave_count
FROM enter
FULL JOIN enroute
    ON enter.vehicle_id = enroute.vehicle_id
FULL JOIN leave
    ON enter.vehicle_id = leave.vehicle_id
WHERE enter.count != leave.count OR leave.count IS NULL
ORDER BY enroute.vehicle_id, enter.vehicle_id, leave.vehicle_id;
DROP TABLE IF EXISTS count_mov_type;

--SELECT * FROM enter_enroute_leave;

*/
--------------------------------------- Calculations for checking all scenarios -----------------------------------------------------------------------------------------------------------------------
SET SEARCH_PATH TO public;

/*
DROP TABLE IF EXISTS cars_driving_by_hour;
CREATE TABLE cars_driving_by_hour AS
WITH
    sc1 AS (SELECT * FROM reference_2019.statistics_by_hour),
    sc2 AS (SELECT * FROM conservative.statistics_by_hour),
    sc3 AS (SELECT * FROM optimistic_PHEV.statistics_by_hour),
    sc4 AS (SELECT * FROM optimistic_EV.statistics_by_hour),
    sc5 AS (SELECT * FROM EV_only.statistics_by_hour)
SELECT
    hour.hour_time,
    sc1.car_count AS reference_2019,
    sc2.car_count AS conservative,
    sc3.car_count AS optimistic_PHEV,
    sc4.car_count AS optimistic_EV,
    sc5.car_count AS EV_only
FROM hour
    LEFT JOIN sc1 ON hour.hour_time = sc1.hour_time
    LEFT JOIN sc2 ON hour.hour_time = sc2.hour_time
    LEFT JOIN sc3 ON hour.hour_time = sc3.hour_time
    LEFT JOIN sc4 ON hour.hour_time = sc4.hour_time
    LEFT JOIN sc5 ON hour.hour_time = sc5.hour_time;

SELECT * FROM cars_driving_by_hour;


DROP TABLE IF EXISTS level_of_service_by_hour;
CREATE TABLE level_of_service_by_hour AS
WITH
    sc1 AS (SELECT * FROM reference_2019.statistics_by_hour),
    sc2 AS (SELECT * FROM conservative.statistics_by_hour),
    sc3 AS (SELECT * FROM optimistic_PHEV.statistics_by_hour),
    sc4 AS (SELECT * FROM optimistic_EV.statistics_by_hour),
    sc5 AS (SELECT * FROM EV_only.statistics_by_hour)
SELECT
    hour.hour_time,
    sc1.level_of_service AS reference_2019,
    sc2.level_of_service AS conservative,
    sc3.level_of_service AS optimistic_PHEV,
    sc4.level_of_service AS optimistic_EV,
    sc5.level_of_service AS EV_only
FROM hour
    LEFT JOIN sc1 ON hour.hour_time = sc1.hour_time
    LEFT JOIN sc2 ON hour.hour_time = sc2.hour_time
    LEFT JOIN sc3 ON hour.hour_time = sc3.hour_time
    LEFT JOIN sc4 ON hour.hour_time = sc4.hour_time
    LEFT JOIN sc5 ON hour.hour_time = sc5.hour_time;

SELECT * FROM level_of_service_by_hour;


DROP TABLE IF EXISTS level_of_service_duration_tot;
CREATE TABLE level_of_service_duration_tot AS
WITH
    sc1 AS (SELECT * FROM reference_2019.level_of_service_stats),
    sc2 AS (SELECT * FROM conservative.level_of_service_stats),
    sc3 AS (SELECT * FROM optimistic_PHEV.level_of_service_stats),
    sc4 AS (SELECT * FROM optimistic_EV.level_of_service_stats),
    sc5 AS (SELECT * FROM EV_only.level_of_service_stats)
SELECT
    sc1.level_of_service,
    sc1.total_duration AS reference_2019,
    sc2.total_duration AS conservative,
    sc3.total_duration AS optimistic_PHEV,
    sc4.total_duration AS optimistic_EV,
    sc5.total_duration AS EV_only
FROM sc1
    FULL JOIN sc2 ON sc1.level_of_service = sc2.level_of_service
    FULL JOIN sc3 ON sc1.level_of_service = sc3.level_of_service
    FULL JOIN sc4 ON sc1.level_of_service = sc4.level_of_service
    FULL JOIN sc5 ON sc1.level_of_service = sc5.level_of_service
ORDER BY CASE WHEN sc1.level_of_service = 'Freeflow' THEN 1
              WHEN sc1.level_of_service = 'Heavy' THEN 2
              WHEN sc1.level_of_service = 'Satur.' THEN 3
              WHEN sc1.level_of_service = 'St+Go' THEN 4
              WHEN sc1.level_of_service = 'St+Go2' THEN 5
              END;

SELECT * FROM level_of_service_duration_tot;


DROP TABLE IF EXISTS level_of_service_duration_avg;
CREATE TABLE level_of_service_duration_avg AS
WITH
    sc1 AS (SELECT * FROM reference_2019.level_of_service_stats),
    sc2 AS (SELECT * FROM conservative.level_of_service_stats),
    sc3 AS (SELECT * FROM optimistic_PHEV.level_of_service_stats),
    sc4 AS (SELECT * FROM optimistic_EV.level_of_service_stats),
    sc5 AS (SELECT * FROM EV_only.level_of_service_stats)
SELECT
    sc1.level_of_service,
    sc1.avg_duration AS reference_2019,
    sc2.avg_duration AS conservative,
    sc3.avg_duration AS optimistic_PHEV,
    sc4.avg_duration AS optimistic_EV,
    sc5.avg_duration AS EV_only
FROM sc1
    FULL JOIN sc2 ON sc1.level_of_service = sc2.level_of_service
    FULL JOIN sc3 ON sc1.level_of_service = sc3.level_of_service
    FULL JOIN sc4 ON sc1.level_of_service = sc4.level_of_service
    FULL JOIN sc5 ON sc1.level_of_service = sc5.level_of_service
ORDER BY CASE WHEN sc1.level_of_service = 'Freeflow' THEN 1
              WHEN sc1.level_of_service = 'Heavy' THEN 2
              WHEN sc1.level_of_service = 'Satur.' THEN 3
              WHEN sc1.level_of_service = 'St+Go' THEN 4
              WHEN sc1.level_of_service = 'St+Go2' THEN 5
              END;

SELECT * FROM level_of_service_duration_avg;


DROP TABLE IF EXISTS level_of_service_distance_tot;
CREATE TABLE level_of_service_distance_tot AS
WITH
    sc1 AS (SELECT * FROM reference_2019.level_of_service_stats),
    sc2 AS (SELECT * FROM conservative.level_of_service_stats),
    sc3 AS (SELECT * FROM optimistic_PHEV.level_of_service_stats),
    sc4 AS (SELECT * FROM optimistic_EV.level_of_service_stats),
    sc5 AS (SELECT * FROM EV_only.level_of_service_stats)
SELECT
    sc1.level_of_service,
    sc1.trip_distance AS reference_2019,
    sc2.trip_distance AS conservative,
    sc3.trip_distance AS optimistic_PHEV,
    sc4.trip_distance AS optimistic_EV,
    sc5.trip_distance AS EV_only
FROM sc1
    FULL JOIN sc2 ON sc1.level_of_service = sc2.level_of_service
    FULL JOIN sc3 ON sc1.level_of_service = sc3.level_of_service
    FULL JOIN sc4 ON sc1.level_of_service = sc4.level_of_service
    FULL JOIN sc5 ON sc1.level_of_service = sc5.level_of_service
ORDER BY CASE WHEN sc1.level_of_service = 'Freeflow' THEN 1
              WHEN sc1.level_of_service = 'Heavy' THEN 2
              WHEN sc1.level_of_service = 'Satur.' THEN 3
              WHEN sc1.level_of_service = 'St+Go' THEN 4
              WHEN sc1.level_of_service = 'St+Go2' THEN 5
              END;

SELECT * FROM level_of_service_distance_tot;


DROP TABLE IF EXISTS level_of_service_distance_avg;
CREATE TABLE level_of_service_distance_avg AS
WITH
    sc1 AS (SELECT * FROM reference_2019.level_of_service_stats),
    sc2 AS (SELECT * FROM conservative.level_of_service_stats),
    sc3 AS (SELECT * FROM optimistic_PHEV.level_of_service_stats),
    sc4 AS (SELECT * FROM optimistic_EV.level_of_service_stats),
    sc5 AS (SELECT * FROM EV_only.level_of_service_stats)
SELECT
    sc1.level_of_service,
    sc1.avg_distance AS reference_2019,
    sc2.avg_distance AS conservative,
    sc3.avg_distance AS optimistic_PHEV,
    sc4.avg_distance AS optimistic_EV,
    sc5.avg_distance AS EV_only
FROM sc1
    FULL JOIN sc2 ON sc1.level_of_service = sc2.level_of_service
    FULL JOIN sc3 ON sc1.level_of_service = sc3.level_of_service
    FULL JOIN sc4 ON sc1.level_of_service = sc4.level_of_service
    FULL JOIN sc5 ON sc1.level_of_service = sc5.level_of_service
ORDER BY CASE WHEN sc1.level_of_service = 'Freeflow' THEN 1
              WHEN sc1.level_of_service = 'Heavy' THEN 2
              WHEN sc1.level_of_service = 'Satur.' THEN 3
              WHEN sc1.level_of_service = 'St+Go' THEN 4
              WHEN sc1.level_of_service = 'St+Go2' THEN 5
              END;

SELECT * FROM level_of_service_distance_avg;


DROP TABLE IF EXISTS sc1, sc2, sc3, sc4, sc5;
CREATE TABLE sc1 AS SELECT MAX(trip_distance) AS distance FROM reference_2019.link_movement_links GROUP BY vehicle_id, trip_number ORDER BY distance;
ALTER TABLE sc1 ADD COLUMN row_number SERIAL PRIMARY KEY;

CREATE TABLE sc2 AS SELECT MAX(trip_distance) AS distance FROM conservative.link_movement_links GROUP BY vehicle_id, trip_number ORDER BY distance;
ALTER TABLE sc2 ADD COLUMN row_number SERIAL PRIMARY KEY;

CREATE TABLE sc3 AS SELECT MAX(trip_distance) AS distance FROM optimistic_PHEV.link_movement_links GROUP BY vehicle_id, trip_number ORDER BY distance;
ALTER TABLE sc3 ADD COLUMN row_number SERIAL PRIMARY KEY;

CREATE TABLE sc4 AS SELECT MAX(trip_distance) AS distance FROM optimistic_EV.link_movement_links GROUP BY vehicle_id, trip_number ORDER BY distance;
ALTER TABLE sc4 ADD COLUMN row_number SERIAL PRIMARY KEY;

CREATE TABLE sc5 AS SELECT MAX(trip_distance) AS distance FROM EV_only.link_movement_links GROUP BY vehicle_id, trip_number ORDER BY distance;
ALTER TABLE sc5 ADD COLUMN row_number SERIAL PRIMARY KEY;

DROP TABLE IF EXISTS travel_distance_distribution; --Table providing the travel distance in km of each trip for each car
CREATE TABLE travel_distance_distribution AS
WITH
    row_nmb AS (SELECT
        ROW_NUMBER() OVER ()
    FROM reference_2019.link_movement_links
    LIMIT GREATEST((SELECT COUNT(*) FROM sc1), (SELECT COUNT(*) FROM sc2), (SELECT COUNT(*) FROM sc3), (SELECT COUNT(*) FROM sc4), (SELECT COUNT(*) FROM sc5)))
SELECT                                   
    row_nmb.row_number, --The function of the column row_number is to place the columns sc1-sc5 side-by-side, with each column order by ascending distance
    sc1.distance AS reference_2019,
    sc2.distance AS conservative,
    sc3.distance AS optimistic_PHEV,
    sc4.distance AS optimistic_EV,
    sc5.distance AS EV_only
FROM row_nmb
    LEFT JOIN sc1 ON row_nmb.row_number = sc1.row_number
    LEFT JOIN sc2 ON row_nmb.row_number = sc2.row_number
    LEFT JOIN sc3 ON row_nmb.row_number = sc3.row_number
    LEFT JOIN sc4 ON row_nmb.row_number = sc4.row_number
    LEFT JOIN sc5 ON row_nmb.row_number = sc5.row_number
ORDER BY row_nmb.row_number;

COPY travel_distance_distribution(reference_2019, conservative, optimistic_PHEV, optimistic_EV, EV_only)
TO 'C:\Users\arvid\Documents\travel_distance_distribution.csv' DELIMITER ',' CSV HEADER;

--SELECT * FROM travel_distance_distribution LIMIT 1000;

SELECT --Table counting the number of trip in each of the scenarios
    COUNT(reference_2019) AS reference_2019,
    COUNT(conservative) AS conservative,
    COUNT(optimistic_PHEV) AS optimistic_PHEV,
    COUNT(optimistic_EV) AS optimistic_EV,
    COUNT(EV_only) AS EV_only
FROM travel_distance_distribution;
*/
--DROP TABLE IF EXISTS sc1, sc2, sc3, sc4, sc5;

--------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS time_detailed;
CREATE TABLE time_detailed(time_5 time without time zone);
SET client_encoding = 'latin1';
COPY time_detailed
FROM 'C:\Users\arvid\Documents\time_5.csv' DELIMITER ',' CSV HEADER;

--SELECT * FROM time_detailed;

SET SEARCH_PATH TO reference_2019;
--SET SEARCH_PATH TO conservative;
--SET SEARCH_PATH TO optimistic_PHEV;
--SET SEARCH_PATH TO optimistic_EV;
--SET SEARCH_PATH TO EV_only;


DROP TABLE IF EXISTS statistics_detailed; --Table showing cars driving and the average level of service at exactly 0:00, 0:05, 0:10, 0:15, 0:20...
CREATE TABLE statistics_detailed AS  --Total execution time: 00:05:28.727
WITH driving_every_fifth_min AS( --Table of "link_movements" at exactly 0:00, 0:05, 0:10, 0:15, 0:20...
    SELECT
        time_5,
        start_time,
        end_time,
        duration,
        level_of_service,
        public.los_to_number(level_of_service => level_of_service)
    FROM public.time_detailed
    LEFT JOIN results
        ON CAST(results.end_time AS TIME) >= time_detailed.time_5
        AND CAST(results.start_time AS TIME) < time_detailed.time_5
    ORDER BY time_5)
SELECT 
    time_5,
    COUNT(time_5)*10 AS car_count,
    AVG(los_to_number) AS level_of_service
FROM driving_every_fifth_min
GROUP BY time_5
ORDER BY time_5;

--SELECT * FROM statistics_detailed;


