------------------------------------ Importing of data -----------------------------------------------------------------------------------------------------------------------------------

--Step 1: Run code to create new database


--CREATE DATABASE db_2020_12_11;


--Step 2: Manually change connection to the new database


--Step 3: Run code to create postgis extension for encoding of location data and create schemas for restoration of agent files
/*

CREATE EXTENSION postgis;

CREATE SCHEMA agents2019_201029;
CREATE SCHEMA agents2030_sweco_201029;
CREATE SCHEMA agents2030_5_201029;
CREATE SCHEMA agents2030_10_201029;
CREATE SCHEMA agents2030_ev_201029;

*/
--Step 4: Copy, paste and run code under "Commands for CMD" found in Word in CMD (Windows key + R). Remember to first change the names of datafiles in Word as appropriate


--Step 5: Run code to arrange restored data files in PostgreSQL. Remember to first change schema names, as in step 4, according to downloaded data

/*
ALTER SCHEMA mistra_base_2019_201211 RENAME TO reference_2019;
ALTER SCHEMA hbefa_2030_sweco_201211 RENAME TO conservative;
ALTER SCHEMA hbefa_2030_5_201211 RENAME TO optimistic_PHEV;
ALTER SCHEMA hbefa_2030_10_201211 RENAME TO optimistic_EV;
ALTER SCHEMA hbefa_2030_ev_201211 RENAME TO EV_only;


SET SEARCH_PATH TO agents2019_201029;
ALTER TABLE scaper_agents SET SCHEMA reference_2019;

SET SEARCH_PATH TO agents2030_sweco_201029;
ALTER TABLE scaper_agents SET SCHEMA conservative;

SET SEARCH_PATH TO agents2030_5_201029;
ALTER TABLE scaper_agents SET SCHEMA optimistic_PHEV;

SET SEARCH_PATH TO agents2030_10_201029;
ALTER TABLE scaper_agents SET SCHEMA optimistic_EV;

SET SEARCH_PATH TO agents2030_ev_201029;
ALTER TABLE scaper_agents SET SCHEMA EV_only;


DROP SCHEMA agents2019_201029;
DROP SCHEMA agents2030_sweco_201029;
DROP SCHEMA agents2030_5_201029;
DROP SCHEMA agents2030_10_201029;
DROP SCHEMA agents2030_ev_201029;

*/
------------------------------------ Creation of various tables and functions within the public schema -----------------------------------------------------------------------------------------------------------------------------------
SET SEARCH_PATH TO public;
/*
DROP FUNCTION IF EXISTS co2_func(cartype VARCHAR, year INTEGER, co2_wtw FLOAT, fc_g FLOAT, fc_mj FlOAT); -- Function is used for hot emission calculations
CREATE OR REPLACE FUNCTION co2_func(cartype VARCHAR, year INTEGER, co2_wtw FLOAT, fc_g FLOAT, fc_mj FlOAT) RETURNS FLOAT AS $$
DECLARE co2_el FLOAT = 47/3.6; -- 47 g CO2/kWh, 3.6 MJ/kWh => 13.055...56 g CO2/MJ       
        BEGIN
                IF cartype = 'EV' THEN
                        RETURN co2_el * fc_mj;
                ELSEIF cartype = 'PHEV' AND year = 2019 THEN
                        RETURN co2_wtw - (fc_mj - 0.043543 * fc_g) * (127.6030 - co2_el); --Explanation: (fc_mj - 0.043543 * fc_g) is the energy use from the electricity share of the fuel for PHEVs,
                ELSEIF cartype = 'PHEV' AND year = 2030 THEN                              --assuming an energy density of 0.043543 MJ/g = 43.543 MJ/kg for gasoline
                        RETURN co2_wtw - (fc_mj - 0.043543 * fc_g) * (102.7669 - co2_el); --(127.6030 - co2_el) and (102.7669 - co2_el) is the difference in CO2 intensity between the European mix (HBEFA) and the Swedish mix
                ELSE                                                                      -- 102.7669 g CO2/MJ = 459.3708 g CO2/kWh and 102.7669 g CO2/MJ = 369.96084 g CO2/kWh
                        RETURN co2_wtw;
                END IF;
        END;
$$ LANGUAGE plpgsql;


DROP TABLE IF EXISTS public.links;
CREATE TABLE public.links AS
SELECT
        CAST(link_id AS INTEGER),
        --from_id
        --to_id
        length, --length in meters
        CAST(freespeed*3.6 AS INTEGER) AS speed_limit,
        CAST(capacity AS INTEGER),
        CAST(permlanes AS INTEGER),
        --modes
        category AS road_type,
        environment AS area,
        geom
FROM reference_2019.links --could be any scenario
WHERE modes = 'car'
ORDER BY link_id; --Total execution time: 00:00:00.405

--SELECT * FROM public.links LIMIT 1000;

DROP TABLE IF EXISTS cars_in_use_per_municipality;
CREATE TABLE cars_in_use_per_municipality(scenario VARCHAR(32), municipality VARCHAR(32), code SMALLINT, cartype VARCHAR(32), cars_in_use FLOAT);
SET client_encoding = 'latin1';
COPY cars_in_use_per_municipality
FROM 'C:\Users\arvid\Documents\cars_in_use_per_municipality.csv' DELIMITER ',' CSV HEADER;
SET client_encoding = 'UTF8';

--SELECT * FROM cars_in_use_per_municipality;


DROP TABLE IF EXISTS emme_kommun;  --Table matching zones with the corresponding muncipalities in Eastern Sweden. Does not contain all zones it should and therefore only be use as a "translation key" between municipality names and codes
CREATE TABLE emme_kommun(zone_id INT, mn_code VARCHAR(4), municipality VARCHAR(32));
SET client_encoding = 'latin1';
COPY emme_kommun
FROM 'C:\Users\arvid\Documents\emme_kommun.csv' DELIMITER ',' CSV HEADER;
SET client_encoding = 'UTF8';

UPDATE emme_kommun SET municipality = 'Bollnäs' WHERE municipality = 'BollnÃ¤s';
    UPDATE emme_kommun SET municipality = 'Ekerö' WHERE municipality = 'EkerÃ¶';
    UPDATE emme_kommun SET municipality = 'Enköping' WHERE municipality = 'EnkÃ¶ping';
    UPDATE emme_kommun SET municipality = 'Finnspång' WHERE municipality = 'FinspÃ¥ng';
    UPDATE emme_kommun SET municipality = 'Gävle' WHERE municipality = 'GÃ¤vle';
    UPDATE emme_kommun SET municipality = 'Håbo' WHERE municipality = 'HÃ¥bo';
    UPDATE emme_kommun SET municipality = 'Hällefors' WHERE municipality = 'HÃ¤llefors';
    UPDATE emme_kommun SET municipality = 'Järfälla' WHERE municipality = 'JÃ¤rfÃ¤lla';
    UPDATE emme_kommun SET municipality = 'Kungsör' WHERE municipality = 'KungsÃ¶r';
    UPDATE emme_kommun SET municipality = 'Köping' WHERE municipality = 'KÃ¶ping';
    UPDATE emme_kommun SET municipality = 'Laxå' WHERE municipality = 'LaxÃ¥';
    UPDATE emme_kommun SET municipality = 'Lidingö' WHERE municipality = 'LidingÃ¶';
    UPDATE emme_kommun SET municipality = 'Linköping' WHERE municipality = 'LinkÃ¶ping';
    UPDATE emme_kommun SET municipality = 'Mjölby' WHERE municipality = 'MjÃ¶lby';
    UPDATE emme_kommun SET municipality = 'Norrköping' WHERE municipality = 'NorrkÃ¶ping';
    UPDATE emme_kommun SET municipality = 'Norrtälje' WHERE municipality = 'NorrtÃ¤lje';
    UPDATE emme_kommun SET municipality = 'Nyköping' WHERE municipality = 'NykÃ¶ping';
    UPDATE emme_kommun SET municipality = 'Nynäshamn' WHERE municipality = 'NynÃ¤shamn';
    UPDATE emme_kommun SET municipality = 'Ovanåker' WHERE municipality = 'OvanÃ¥ker';
    UPDATE emme_kommun SET municipality = 'Oxelösund' WHERE municipality = 'OxelÃ¶sund';
    UPDATE emme_kommun SET municipality = 'Strängnäs' WHERE municipality = 'StrÃ¤ngnÃ¤s';
    UPDATE emme_kommun SET municipality = 'Söderhamn' WHERE municipality = 'SÃ¶derhamn';
    UPDATE emme_kommun SET municipality = 'Söderköping' WHERE municipality = 'SÃ¶derkÃ¶ping';
    UPDATE emme_kommun SET municipality = 'Södertälje' WHERE municipality = 'SÃ¶dertÃ¤lje';
    UPDATE emme_kommun SET municipality = 'Tyresö' WHERE municipality = 'TyresÃ¶';
    UPDATE emme_kommun SET municipality = 'Täby' WHERE municipality = 'TÃ¤by';
    UPDATE emme_kommun SET municipality = 'Uppl. Bro' WHERE municipality = 'Upplands-Bro';
    UPDATE emme_kommun SET municipality = 'Uppl. Väsby' WHERE municipality = 'Upplands VÃ¤sby';
    UPDATE emme_kommun SET municipality = 'Vingåker' WHERE municipality = 'VingÃ¥ker';
    UPDATE emme_kommun SET municipality = 'Värmdö' WHERE municipality = 'VÃ¤rmdÃ¶';
    UPDATE emme_kommun SET municipality = 'Västerås' WHERE municipality = 'VÃ¤sterÃ¥s';
    UPDATE emme_kommun SET municipality = 'Åtvidaberg' WHERE municipality = 'Ãtvidaberg';
    UPDATE emme_kommun SET municipality = 'Älvkarleby' WHERE municipality = 'Ãlvkarleby';
    UPDATE emme_kommun SET municipality = 'Ödeshög' WHERE municipality = 'ÃdeshÃ¶g';
    UPDATE emme_kommun SET municipality = 'Örebro' WHERE municipality = 'Ãrebro';
    UPDATE emme_kommun SET municipality = 'Österåker' WHERE municipality = 'ÃsterÃ¥ker';
    UPDATE emme_kommun SET municipality = 'Östhammar' WHERE municipality = 'Ãsthammar';
UPDATE emme_kommun SET mn_code = CONCAT('0', mn_code) WHERE LENGTH(mn_code)=3;


DROP TABLE IF EXISTS zones_by_municipality;
CREATE TABLE zones_by_municipality AS
WITH
mn_code_mn_name AS(
        SELECT
                mn_code,
                municipality
        FROM emme_kommun
        GROUP BY mn_code, municipality),
mn_name_mn_geom AS( --For some reason the table scb_kommun consists of only dual entries, i.e. is twice as long as it should
SELECT
        municipality,
        totbef,
        wkb_geometry
FROM scb_kommun
GROUP BY municipality, totbef, wkb_geometry)
SELECT
        mn_code_mn_name.municipality,
        CAST(mn_name_mn_geom.municipality AS INTEGER) AS mn_code,
        mn_name_mn_geom.totbef AS mn_pop,
        sverige_tz_epsg3006.zone AS zone_id,
        sverige_tz_epsg3006.area AS zone_area,
        sverige_tz_epsg3006.wkb_geometry AS geom
FROM sverige_tz_epsg3006
LEFT JOIN mn_name_mn_geom
        ON ST_CONTAINS(mn_name_mn_geom.wkb_geometry, ST_CENTROID(sverige_tz_epsg3006.wkb_geometry))
LEFT JOIN mn_code_mn_name
        ON mn_code_mn_name.mn_code = mn_name_mn_geom.municipality
WHERE mn_code_mn_name.mn_code LIKE '0%' AND CAST(RIGHT(mn_code_mn_name.mn_code, 3) AS INTEGER) <= 192 --Condition for only selecting municipalities in Stockholm County
ORDER BY municipality, zone_id;

INSERT INTO zones_by_municipality(municipality, mn_code, mn_pop, zone_id, zone_area, geom)
VALUES
    ('Norrtälje', '0188', 60717, 718834, 416000000.0, (SELECT wkb_geometry FROM sverige_tz_epsg3006 WHERE zone = 718834)),
    ('Norrtälje', '0188', 60717, 718837, 143000000.0, (SELECT wkb_geometry FROM sverige_tz_epsg3006 WHERE zone = 718837));

SELECT * FROM zones_by_municipality;


DROP TABLE IF EXISTS municipalities;--Table with municipality borders
CREATE TABLE municipalities AS
SELECT 
    municipality,
    mn_code,
    ST_Union(ST_SnapToGrid(geom, 0.0001)) AS geom
FROM zones_by_municipality
GROUP BY municipality, mn_code
ORDER BY municipality;

--SELECT * FROM municipalities;


*/
------------------------------------ Evporation losses calculations -----------------------------------------------------------------------------------------------------------------------------------
/*

DROP TABLE IF EXISTS evap_diurnal_org; --given in g/day
CREATE TABLE evap_diurnal_org(
        "Case" VARCHAR(32),
        VehCat VARCHAR(32),
        Year SMALLINT,
        TrafficScenario VARCHAR(32),
        Component VARCHAR(32),
        RoadCat VARCHAR(32),
        AmbientCondPattern VARCHAR(32),
        EmConcept VARCHAR(32),
        "%OfEmConcept" FLOAT,
        EFA FLOAT,
        EFA_weighted FLOAT);
SET client_encoding = 'latin1';
COPY evap_diurnal_org
FROM 'C:\Users\arvid\Documents\evaporation_diurnal.csv' DELIMITER ',' CSV HEADER
WHERE EmConcept != 'bifuel CNG/petrol' AND EmConcept != 'flex-fuel E85' AND component != 'CH4'; --Emission factors for CH4 are 0
SET client_encoding = 'UTF8';

UPDATE evap_diurnal_org SET emconcept = 'Gasoline' WHERE emconcept = 'petrol (4S)';
UPDATE evap_diurnal_org SET emconcept = 'Diesel' WHERE emconcept = 'diesel';
UPDATE evap_diurnal_org SET emconcept = 'PHEV' WHERE emconcept = 'Plug-in Hybrid petrol/electric';
UPDATE evap_diurnal_org SET emconcept = 'EV' WHERE emconcept = 'electricity';


DROP TABLE IF EXISTS evap_diurnal;
CREATE TABLE evap_diurnal AS
WITH
        Benzene AS (SELECT * FROM evap_diurnal_org WHERE component = 'Benzene'),
        HC AS (SELECT * FROM evap_diurnal_org WHERE component = 'HC'),
        NMHC AS (SELECT * FROM evap_diurnal_org WHERE component = 'NMHC')
SELECT
        Benzene.emconcept AS cartype,
        Benzene.year AS year,
        Benzene.efa AS Benzene,
        HC.efa AS HC,
        NMHC.efa AS NMHC
FROM Benzene
LEFT JOIN HC ON Benzene.emconcept = HC.emconcept AND Benzene.year = HC.year
LEFT JOIN NMHC ON Benzene.emconcept = NMHC.emconcept AND Benzene.year = NMHC.year
ORDER BY year, CASE WHEN Benzene.emconcept = 'Gasoline' THEN 1
                    WHEN Benzene.emconcept = 'Diesel' THEN 2
                    WHEN Benzene.emconcept = 'PHEV' THEN 3
                    WHEN Benzene.emconcept = 'EV' THEN 4
                    END;

CREATE INDEX IF NOT EXISTS evap_diurnal_cartype_idx ON evap_diurnal(cartype);
CREATE INDEX IF NOT EXISTS evap_diurnal_year_idx ON evap_diurnal(year);

--SELECT * FROM evap_diurnal;


DROP TABLE IF EXISTS evap_running_org; --given in g/km
CREATE TABLE evap_running_org(
        "Case" VARCHAR(32),
        VehCat VARCHAR(32),
        Year SMALLINT,
        TrafficScenario VARCHAR(32),
        Component VARCHAR(32),
        RoadCat VARCHAR(32),
        AmbientCondPattern VARCHAR(32),
        EmConcept VARCHAR(32),
        "%OfEmConcept" FLOAT,
        EFA FLOAT,
        EFA_weighted FLOAT);
SET client_encoding = 'latin1';
COPY evap_running_org
FROM 'C:\Users\arvid\Documents\evaporation_running.csv' DELIMITER ',' CSV HEADER
WHERE EmConcept != 'bifuel CNG/petrol' AND EmConcept != 'flex-fuel E85' AND component != 'CH4'; --Emission factors for CH4 are 0
SET client_encoding = 'UTF8';

UPDATE evap_running_org SET emconcept = 'Gasoline' WHERE emconcept = 'petrol (4S)';
UPDATE evap_running_org SET emconcept = 'Diesel' WHERE emconcept = 'diesel';
UPDATE evap_running_org SET emconcept = 'PHEV' WHERE emconcept = 'Plug-in Hybrid petrol/electric';
UPDATE evap_running_org SET emconcept = 'EV' WHERE emconcept = 'electricity';
UPDATE evap_running_org SET RoadCat = 'RUR' WHERE RoadCat = 'Rural';
UPDATE evap_running_org SET RoadCat = 'URB' WHERE RoadCat = 'Urban';

DROP TABLE IF EXISTS evap_running;
CREATE TABLE evap_running AS
WITH
        Benzene AS (SELECT * FROM evap_running_org WHERE component = 'Benzene'),
        HC AS (SELECT * FROM evap_running_org WHERE component = 'HC'),
        NMHC AS (SELECT * FROM evap_running_org WHERE component = 'NMHC')
SELECT
        Benzene.emconcept AS cartype,
        Benzene.year AS year,
        Benzene.RoadCat as road_category,
        Benzene.efa AS Benzene,
        HC.efa AS HC,
        NMHC.efa AS NMHC
FROM Benzene
LEFT JOIN HC ON Benzene.emconcept = HC.emconcept AND Benzene.year = HC.year AND Benzene.RoadCat = HC.RoadCat
LEFT JOIN NMHC ON Benzene.emconcept = NMHC.emconcept AND Benzene.year = NMHC.year AND Benzene.RoadCat = NMHC.RoadCat
ORDER BY year, road_category, CASE WHEN Benzene.emconcept = 'Gasoline' THEN 1
                                   WHEN Benzene.emconcept = 'Diesel' THEN 2
                                   WHEN Benzene.emconcept = 'PHEV' THEN 3
                                   WHEN Benzene.emconcept = 'EV' THEN 4
                                   END;

CREATE INDEX IF NOT EXISTS evap_running_cartype_idx ON evap_running(cartype);
CREATE INDEX IF NOT EXISTS evap_running_year_idx ON evap_running(year);
CREATE INDEX IF NOT EXISTS evap_running_road_category_idx ON evap_running(road_category);

--SELECT * FROM evap_running;


DROP TABLE IF EXISTS evap_soak_org; --given in g/stop
CREATE TABLE evap_soak_org(
        "Case" VARCHAR(32),
        VehCat VARCHAR(32),
        Year SMALLINT,
        TrafficScenario VARCHAR(32),
        Component VARCHAR(32),
        RoadCat VARCHAR(32),
        AmbientCondPattern VARCHAR(32),
        EmConcept VARCHAR(32),
        "%OfEmConcept" FLOAT,
        EFA FLOAT,
        EFA_weighted FLOAT);
SET client_encoding = 'latin1';
COPY evap_soak_org
FROM 'C:\Users\arvid\Documents\evaporation_soak.csv' DELIMITER ',' CSV HEADER
WHERE EmConcept != 'bifuel CNG/petrol' AND EmConcept != 'flex-fuel E85' AND component != 'CH4'; --Emission factors for CH4 are 0
SET client_encoding = 'UTF8';

UPDATE evap_soak_org SET emconcept = 'Gasoline' WHERE emconcept = 'petrol (4S)';
UPDATE evap_soak_org SET emconcept = 'Diesel' WHERE emconcept = 'diesel';
UPDATE evap_soak_org SET emconcept = 'PHEV' WHERE emconcept = 'Plug-in Hybrid petrol/electric';
UPDATE evap_soak_org SET emconcept = 'EV' WHERE emconcept = 'electricity';


DROP TABLE IF EXISTS evap_soak;
CREATE TABLE evap_soak AS
WITH
        Benzene AS (SELECT * FROM evap_soak_org WHERE component = 'Benzene'),
        HC AS (SELECT * FROM evap_soak_org WHERE component = 'HC'),
        NMHC AS (SELECT * FROM evap_soak_org WHERE component = 'NMHC')
SELECT
        Benzene.emconcept AS cartype,
        Benzene.year AS year,
        Benzene.efa AS Benzene,
        HC.efa AS HC,
        NMHC.efa AS NMHC
FROM Benzene
LEFT JOIN HC ON Benzene.emconcept = HC.emconcept AND Benzene.year = HC.year
LEFT JOIN NMHC ON Benzene.emconcept = NMHC.emconcept AND Benzene.year = NMHC.year
ORDER BY year, CASE WHEN Benzene.emconcept = 'Gasoline' THEN 1
                    WHEN Benzene.emconcept = 'Diesel' THEN 2
                    WHEN Benzene.emconcept = 'PHEV' THEN 3
                    WHEN Benzene.emconcept = 'EV' THEN 4
                    END;

CREATE INDEX IF NOT EXISTS evap_soak_cartype_idx ON evap_soak(cartype);
CREATE INDEX IF NOT EXISTS evap_soak_year_idx ON evap_soak(year);

--SELECT * FROM evap_soak;

DROP TABLE IF EXISTS evap_diurnal_org, evap_running_org, evap_soak_org;

*/
------------------------------------ Cold start calculations -----------------------------------------------------------------------------------------------------------------------------------
/*

DROP TABLE IF EXISTS cold_start_org;
CREATE TABLE cold_start_org(Year SMALLINT, Component VARCHAR(32), AmbientCondPattern VARCHAR(32), EmConcept VARCHAR(32), EFA FLOAT, EFA_WTW FLOAT);
SET client_encoding = 'latin1';
COPY cold_start_org
FROM 'C:\Users\arvid\Documents\hbefa_cold.csv' DELIMITER ',' CSV HEADER
WHERE EmConcept != 'bifuel CNG/petrol' AND EmConcept != 'flex-fuel E85';
SET client_encoding = 'UTF8';

UPDATE cold_start_org SET emconcept = 'Gasoline' WHERE emconcept = 'petrol (4S)';
UPDATE cold_start_org SET emconcept = 'Diesel' WHERE emconcept = 'diesel';
UPDATE cold_start_org SET emconcept = 'PHEV' WHERE emconcept = 'Plug-in Hybrid petrol/electric';
UPDATE cold_start_org SET emconcept = 'EV' WHERE emconcept = 'electricity';
INSERT INTO cold_start_org(Year, Component, AmbientCondPattern, EmConcept, EFA, EFA_WTW) --Here, essentially, a new component 'CO2_WTW' is added as rows at the end of the table based on that EFA is assigned the values of EFA_WTW (EFA_WTW is only defined for where component = 'CO2e')
        SELECT Year, 'CO2_WTW', AmbientCondPattern, EmConcept, EFA_WTW, EFA_WTW
        FROM cold_start_org WHERE Component = 'CO2e';


DROP TABLE IF EXISTS cold_start_1;
CREATE TABLE cold_start_1 AS
WITH cold_start_split AS (SELECT
        year,
        component,
        split_part(ambientcondpattern, ',', 1) AS temperature,
        TRIM('h' FROM split_part(ambientcondpattern, ',', 2)) AS parking_duration,
        CASE WHEN split_part(ambientcondpattern, ',', 3) != '>20km'
                THEN (CAST(split_part(TRIM('km' FROM split_part(ambientcondpattern, ',', 3)), '-', 1) AS FLOAT) + CAST(split_part(TRIM('km' FROM split_part(ambientcondpattern, ',', 3)), '-', 2) AS INTEGER))/2 --Average distance of distance intveral, e.g. for 1-2 km = avg_distance = 1.5 km
                ELSE 30 --For trip length of > 20 km in HBEFA 30 km is the average distance
        END AS avg_distance,
        emconcept AS cartype,
        efa
        FROM cold_start_org)
SELECT
        cold_start_split.year,
        cold_start_split.component,
        cold_start_split.cartype,
        CASE WHEN temperature = 'TØ'
                THEN 'average'
                ELSE TRIM('T+°C' from temperature)
        END AS temperature,
        CASE WHEN parking_duration LIKE '>%'
                THEN CAST(TRIM('>' from parking_duration) AS SMALLINT)
                ELSE CAST(split_part(parking_duration, '-', 1) AS SMALLINT)
        END AS lower_p_bound,
        CASE WHEN parking_duration LIKE '>%'
                THEN 1000
                ELSE CAST(split_part(parking_duration, '-', 2) AS SMALLINT)
        END AS upper_p_bound,
        avg_distance,
        efa
        FROM cold_start_split
ORDER BY year, component, temperature, lower_p_bound, avg_distance, cartype;
DELETE FROM cold_start_1 WHERE upper_p_bound = 5 AND temperature = '20'; --Presumably due to some bug in HBEFA all these emission factors equal zero
UPDATE cold_start_1 SET upper_p_bound = 8 WHERE upper_p_bound = 4 AND temperature = '20'; --Necessary adjustment since HBEFA does not provide emission factors for parking times between 5 and 12 hours for 20 °C
UPDATE cold_start_1 SET lower_p_bound = 8 WHERE lower_p_bound = 12 AND temperature = '20'; --See comment above


DROP TABLE IF EXISTS cold_start_2;
CREATE TABLE cold_start_2 AS
WITH
        cold_start_0_5 AS (SELECT* FROM cold_start_1 WHERE avg_distance = 0.5),
        cold_start_1_5 AS (SELECT* FROM cold_start_1 WHERE avg_distance = 1.5),
        cold_start_2_5 AS (SELECT* FROM cold_start_1 WHERE avg_distance = 2.5),
        cold_start_3_5 AS (SELECT* FROM cold_start_1 WHERE avg_distance = 3.5),
        cold_start_4_5 AS (SELECT* FROM cold_start_1 WHERE avg_distance = 4.5),
        cold_start_30 AS (SELECT* FROM cold_start_1 WHERE avg_distance = 30)
SELECT
        cold_start_0_5.year,
        cold_start_0_5.component,
        cold_start_0_5.cartype,
        cold_start_0_5.temperature,
        cold_start_0_5.lower_p_bound,
        cold_start_0_5.upper_p_bound,
        cold_start_0_5.efa AS efa_0_5,
        cold_start_1_5.efa AS efa_1_5,
        cold_start_2_5.efa AS efa_2_5,
        cold_start_3_5.efa AS efa_3_5,
        cold_start_4_5.efa AS efa_4_5,
        cold_start_30.efa AS efa_30
FROM cold_start_0_5
        FULL JOIN cold_start_1_5 ON cold_start_0_5.year = cold_start_1_5.year AND cold_start_0_5.component = cold_start_1_5.component AND cold_start_0_5.cartype = cold_start_1_5.cartype AND cold_start_0_5.temperature = cold_start_1_5.temperature AND cold_start_0_5.lower_p_bound = cold_start_1_5.lower_p_bound
        FULL JOIN cold_start_2_5 ON cold_start_0_5.year = cold_start_2_5.year AND cold_start_0_5.component = cold_start_2_5.component AND cold_start_0_5.cartype = cold_start_2_5.cartype AND cold_start_0_5.temperature = cold_start_2_5.temperature AND cold_start_0_5.lower_p_bound = cold_start_2_5.lower_p_bound
        FULL JOIN cold_start_3_5 ON cold_start_0_5.year = cold_start_3_5.year AND cold_start_0_5.component = cold_start_3_5.component AND cold_start_0_5.cartype = cold_start_3_5.cartype AND cold_start_0_5.temperature = cold_start_3_5.temperature AND cold_start_0_5.lower_p_bound = cold_start_3_5.lower_p_bound
        FULL JOIN cold_start_4_5 ON cold_start_0_5.year = cold_start_4_5.year AND cold_start_0_5.component = cold_start_4_5.component AND cold_start_0_5.cartype = cold_start_4_5.cartype AND cold_start_0_5.temperature = cold_start_4_5.temperature AND cold_start_0_5.lower_p_bound = cold_start_4_5.lower_p_bound
        FULL JOIN cold_start_30 ON cold_start_0_5.year = cold_start_30.year AND cold_start_0_5.component = cold_start_30.component AND cold_start_0_5.cartype = cold_start_30.cartype AND cold_start_0_5.temperature = cold_start_30.temperature AND cold_start_0_5.lower_p_bound = cold_start_30.lower_p_bound
ORDER BY year, temperature, component, lower_p_bound, cartype;

--SELECT * FROM cold_start_2 WHERE efa_0_5 != 0; --This data is exported to Excel where the constants lambda and M_tot ane determined separately, according to the method of least sqares, for 576 ambient condition patterns in order for cold start emissions to be calculated as exponentially decreasing as a function of the travel distance.

DROP TABLE IF EXISTS cold_start_3;
CREATE TABLE cold_start_3(
        year SMALLINT,
        component VARCHAR(32),
        cartype VARCHAR(32),
        temperature VARCHAR(32),
        lower_p_bound SMALLINT,
        upper_p_bound SMALLINT,
        lambda FLOAT,
        M_tot FLOAT);
SET client_encoding = 'latin1';
COPY cold_start_3
FROM 'C:\Users\arvid\Documents\cold_start.csv' DELIMITER ',' CSV HEADER;
SET client_encoding = 'UTF8';


DROP TABLE IF EXISTS cold_start_4; --As opposed to "cold_start_3" this table also contain null values representing component/cartype combinations with no cold start emissions
CREATE TABLE cold_start_4 AS
SELECT
        cold_start_2.year,
        cold_start_2.component,
        cold_start_2.cartype,
        cold_start_2.temperature,
        make_interval(HOURS => cold_start_2.lower_p_bound) AS lower_p_bound,
        make_interval(HOURS => cold_start_2.upper_p_bound) AS upper_p_bound,
        cold_start_3.lambda,
        cold_start_3.m_tot
FROM cold_start_2 LEFT JOIN cold_start_3
        ON cold_start_2.year = cold_start_3.year
        AND cold_start_2.component = cold_start_3.component
        AND cold_start_2.cartype = cold_start_3.cartype
        AND cold_start_2.temperature = cold_start_3.temperature        
        AND cold_start_2.lower_p_bound = cold_start_3.lower_p_bound
ORDER BY year, temperature, component, lower_p_bound, cartype;


DROP TABLE IF EXISTS cold_start;
CREATE TABLE cold_start AS --Compared to the table "hot_emissions", "cold_start" does not include "bc_non_exhaust", "n2o", "nh3", "pm10_non_exhaust" and "pm25_non_exhaust"
WITH
        BC_exhaust AS (SELECT * FROM cold_start_4 WHERE component = 'BC (exhaust)'),
        Benzene AS (SELECT * FROM cold_start_4 WHERE component = 'Benzene'),
        CH4 AS (SELECT * FROM cold_start_4 WHERE component = 'CH4'),
        CO AS (SELECT * FROM cold_start_4 WHERE component = 'CO'),
        CO2_ttw AS (SELECT * FROM cold_start_4 WHERE component = 'CO2e'),
        CO2_wtw AS (SELECT * FROM cold_start_4 WHERE component = 'CO2_WTW'),
        FC_g AS (SELECT * FROM cold_start_4 WHERE component = 'FC'),
        FC_MJ AS (SELECT * FROM cold_start_4 WHERE component = 'FC_MJ'),
        HC AS (SELECT * FROM cold_start_4 WHERE component = 'HC'),
        NMHC AS (SELECT * FROM cold_start_4 WHERE component = 'NMHC'),
        NO2 AS (SELECT * FROM cold_start_4 WHERE component = 'NO2'),
        NOx AS (SELECT * FROM cold_start_4 WHERE component = 'NOx'),
        Pb AS (SELECT * FROM cold_start_4 WHERE component = 'Pb'),
        PM25_exhaust AS (SELECT * FROM cold_start_4 WHERE component = 'PM2.5'),
        PN AS (SELECT * FROM cold_start_4 WHERE component = 'PN'),
        SO2 AS (SELECT * FROM cold_start_4 WHERE component = 'SO2')
SELECT
        bc_exhaust.year,
        bc_exhaust.cartype,
        bc_exhaust.temperature,
        bc_exhaust.lower_p_bound,
        bc_exhaust.upper_p_bound,
        bc_exhaust.m_tot AS bc_exhaust,
        benzene.m_tot AS benzene,
        ch4.m_tot AS ch4,
        co.m_tot AS co,
        co2_wtw.m_tot AS co2_WTW, --(SELECT co2_func(cartype => co2e.cartype, year => co2e.year, co2_wtw => co2e.m_tot_wtw, fc_g => fc_g.m_tot, fc_mj => fc_mj.m_tot)) AS co2_WTW, --This way of calculating co2_wtw results in the same co2_wtw emission since there are no cold start execess emissions from the use of electricity in electric cars and plug-in hybrids
        co2_ttw.m_tot AS co2_TTW,
        fc_g.m_tot AS fc_g,
        fc_mj.m_tot AS fc_mj,
        hc.m_tot AS hc,
        nmhc.m_tot AS nmhc,
        no2.m_tot AS no2,
        nox.m_tot AS nox,
        pb.m_tot AS pb,
        pm25_exhaust.m_tot AS pm25_exhaust,    
        pn.m_tot AS pn,
        so2.m_tot AS so2,
        bc_exhaust.lambda AS lambda_bc_exhaust,
        benzene.lambda AS lambda_benzene,
        ch4.lambda AS lambda_ch4,
        co.lambda AS lambda_co,
        co2_ttw.lambda AS lambda_co2, --The same lambda is used for both co2_ttw and co2_wtw
        fc_g.lambda AS lambda_fc, -- The same lambda is used for both fc_g and fc_mj
        hc.lambda AS lambda_hc,
        nmhc.lambda AS lambda_nmhc,
        no2.lambda AS lambda_no2,
        nox.lambda AS lambda_nox,
        pb.lambda AS lambda_pb,
        pm25_exhaust.lambda AS lambda_pm25_exhaust,
        pn.lambda AS lambda_pn,
        so2.lambda AS lambda_so2
FROM bc_exhaust
        LEFT JOIN benzene ON bc_exhaust.lower_p_bound = benzene.lower_p_bound AND bc_exhaust.cartype = benzene.cartype AND bc_exhaust.temperature = benzene.temperature AND bc_exhaust.year = benzene.year
        LEFT JOIN ch4 ON bc_exhaust.lower_p_bound = ch4.lower_p_bound AND bc_exhaust.cartype = ch4.cartype AND bc_exhaust.temperature = ch4.temperature AND bc_exhaust.year = ch4.year
        LEFT JOIN co ON bc_exhaust.lower_p_bound = co.lower_p_bound AND bc_exhaust.cartype = co.cartype AND bc_exhaust.temperature = co.temperature AND bc_exhaust.year = co.year
        LEFT JOIN co2_wtw ON bc_exhaust.lower_p_bound = co2_wtw.lower_p_bound AND bc_exhaust.cartype = co2_wtw.cartype AND bc_exhaust.temperature = co2_wtw.temperature AND bc_exhaust.year = co2_wtw.year
        LEFT JOIN co2_ttw ON bc_exhaust.lower_p_bound = co2_ttw.lower_p_bound AND bc_exhaust.cartype = co2_ttw.cartype AND bc_exhaust.temperature = co2_ttw.temperature AND bc_exhaust.year = co2_ttw.year
        LEFT JOIN fc_g ON bc_exhaust.lower_p_bound = fc_g.lower_p_bound AND bc_exhaust.cartype = fc_g.cartype AND bc_exhaust.temperature = fc_g.temperature AND bc_exhaust.year = fc_g.year
        LEFT JOIN fc_mj ON bc_exhaust.lower_p_bound = fc_mj.lower_p_bound AND bc_exhaust.cartype = fc_mj.cartype AND bc_exhaust.temperature = fc_mj.temperature AND bc_exhaust.year = fc_mj.year
        LEFT JOIN hc ON bc_exhaust.lower_p_bound = hc.lower_p_bound AND bc_exhaust.cartype = hc.cartype AND bc_exhaust.temperature = hc.temperature AND bc_exhaust.year = hc.year         
        LEFT JOIN nmhc ON bc_exhaust.lower_p_bound = nmhc.lower_p_bound AND bc_exhaust.cartype = nmhc.cartype AND bc_exhaust.temperature = nmhc.temperature AND bc_exhaust.year = nmhc.year
        LEFT JOIN no2 ON bc_exhaust.lower_p_bound = no2.lower_p_bound AND bc_exhaust.cartype = no2.cartype AND bc_exhaust.temperature = no2.temperature AND bc_exhaust.year = no2.year
        LEFT JOIN nox ON bc_exhaust.lower_p_bound = nox.lower_p_bound AND bc_exhaust.cartype = nox.cartype AND bc_exhaust.temperature = nox.temperature AND bc_exhaust.year = nox.year
        LEFT JOIN pb ON bc_exhaust.lower_p_bound = pb.lower_p_bound AND bc_exhaust.cartype = pb.cartype AND bc_exhaust.temperature = pb.temperature AND bc_exhaust.year = pb.year                         
        LEFT JOIN pm25_exhaust ON bc_exhaust.lower_p_bound = pm25_exhaust.lower_p_bound AND bc_exhaust.cartype = pm25_exhaust.cartype AND bc_exhaust.temperature = pm25_exhaust.temperature AND bc_exhaust.year = pm25_exhaust.year
        LEFT JOIN pn ON bc_exhaust.lower_p_bound = pn.lower_p_bound AND bc_exhaust.cartype = pn.cartype AND bc_exhaust.temperature = pn.temperature AND bc_exhaust.year = pn.year
        LEFT JOIN so2 ON bc_exhaust.lower_p_bound = so2.lower_p_bound AND bc_exhaust.cartype = so2.cartype AND bc_exhaust.temperature = so2.temperature AND bc_exhaust.year = so2.year
ORDER BY year, temperature, lower_p_bound, CASE WHEN bc_exhaust.cartype = 'Gasoline' THEN 1
                                                WHEN bc_exhaust.cartype = 'Diesel' THEN 2
                                                WHEN bc_exhaust.cartype = 'PHEV' THEN 3
                                                WHEN bc_exhaust.cartype = 'EV' THEN 4
                                                END;

CREATE INDEX IF NOT EXISTS cold_start_year_idx ON public.cold_start(year);
CREATE INDEX IF NOT EXISTS cold_start_cartype_idx ON public.cold_start(cartype);
CREATE INDEX IF NOT EXISTS cold_start_temperature_idx ON public.cold_start(temperature);
CREATE INDEX IF NOT EXISTS cold_start_lower_p_bound_idx ON public.cold_start(lower_p_bound);
CREATE INDEX IF NOT EXISTS cold_start_upper_p_bound_idx ON public.cold_start(upper_p_bound);

--SELECT * FROM cold_start;

DROP TABLE IF EXISTS cold_start_org, cold_start_1, cold_start_2, cold_start_3, cold_start_4; --Here all intermediate cold_start tables are dropped

*/
------------------------------------ Hot emission factor calculations --------------------------------------------------------------------------------------------------------------------------
/*

DROP TABLE IF EXISTS los_org;
CREATE TABLE los_org(code VARCHAR(6), los INTEGER, speed_limit INTEGER, v_avg FLOAT, std_v FLOAT, lower_bound FLOAT, upper_bound FLOAT);
COPY los_org
FROM 'C:\Users\arvid\Documents\los.csv' DELIMITER ',' CSV HEADER;


DROP TABLE IF EXISTS los;
CREATE TABLE los AS
SELECT
        CASE WHEN code LIKE '1%' THEN 'RUR'
             ELSE 'URB'
             END
        AS area,
        CASE WHEN code LIKE '_10%' THEN 'MW-Nat.'
                WHEN code LIKE '_12%' THEN 'Semi-MW'
                WHEN code LIKE '_20%' THEN 'Trunk-Nat.' --Primary-nat. non-motorway
                WHEN code LIKE '_30%' THEN 'Distr'
                WHEN code LIKE '_31%' THEN 'Distr-sin.'
                WHEN code LIKE '_40%' THEN 'Local'
                WHEN code LIKE '_41%' THEN 'Local-sin.'
                WHEN code LIKE '_50%' THEN 'Access'
                WHEN code LIKE '_11%' THEN 'MW-City'
                WHEN code LIKE '_21%' THEN 'Trunk-City' --Primary-city non-motorway
                ELSE 'error'
                END
        AS road_type,
        speed_limit,
        CASE WHEN los = 1 THEN 'Freeflow'
                WHEN los = 2 THEN 'Heavy'
                WHEN los = 3 THEN 'Satur.'
                WHEN los = 4 THEN 'St+Go'
                WHEN los = 5 THEN 'St+Go2'
                ELSE 'error'
                END
        AS level_of_service,
        lower_bound AS lower_v_bound,
        upper_bound AS upper_v_bound,
        v_avg,
        std_v
FROM los_org WHERE speed_limit <= 120;

CREATE INDEX IF NOT EXISTS los_area_idx ON public.los(area);
CREATE INDEX IF NOT EXISTS los_road_type_idx ON public.los(road_type);
CREATE INDEX IF NOT EXISTS los_speed_limit_idx ON public.los(speed_limit);
CREATE INDEX IF NOT EXISTS los_lower_p_bound_idx ON public.los(lower_v_bound);
CREATE INDEX IF NOT EXISTS los_upper_p_bound_idx ON public.los(upper_v_bound);

--SELECT * FROM los;


DROP TABLE IF EXISTS hot_emissions_org;
CREATE TABLE hot_emissions_org(Year SMALLINT, Component VARCHAR(32), TrafficSit VARCHAR(32), EmConcept VARCHAR(32), EFA FLOAT, EFA_WTW FLOAT);
SET client_encoding = 'latin1';
COPY hot_emissions_org
FROM 'C:\Users\arvid\Documents\HBEFA_hot.csv' DELIMITER ',' CSV HEADER
WHERE EmConcept != 'bifuel CNG/petrol' AND EmConcept != 'flex-fuel E85';

UPDATE hot_emissions_org SET emconcept = 'Gasoline' WHERE emconcept = 'petrol (4S)';
UPDATE hot_emissions_org SET emconcept = 'Diesel' WHERE emconcept = 'diesel';
UPDATE hot_emissions_org SET emconcept = 'EV' WHERE emconcept = 'electricity';
UPDATE hot_emissions_org SET emconcept = 'PHEV' WHERE emconcept = 'Plug-in Hybrid petrol/electric';


DROP TABLE IF EXISTS hot_emissions;
CREATE TABLE hot_emissions AS
WITH
        hot_emissions_split AS (SELECT
                Year AS year,
                EmConcept AS cartype,
                trafficsit,
                (SELECT split_part(hot_emissions_org.trafficsit, '/', 1)) AS area,
                CASE WHEN (SELECT split_part(hot_emissions_org.trafficsit, '/', 2)) = 'MW' THEN 'MW-Nat.' --The road types 'MW' and 'Trunk', which are given by the Excel file from HBEFA, are redundant
                        WHEN (SELECT split_part(hot_emissions_org.trafficsit, '/', 2)) = 'Trunk' THEN 'Trunk-Nat.'
                        ELSE (SELECT split_part(hot_emissions_org.trafficsit, '/', 2))
                END AS road_type,
                (SELECT (CAST(TRIM('>' FROM split_part(hot_emissions_org.trafficsit, '/', 3)) AS INTEGER))) AS speed_limit,
                (SELECT split_part(hot_emissions_org.trafficsit, '/', 4)) AS level_of_service
                FROM hot_emissions_org
                WHERE component = 'HC'), --Could be any component. The same as: GROUP BY year, trafficsit, area, road_type, speed_limit, level_of_service, cartype),
        BC_exhaust AS (SELECT * FROM hot_emissions_org WHERE component = 'BC (exhaust)'),
        BC_non_exhaust AS (SELECT * FROM hot_emissions_org WHERE component = 'BC (non-exhaust)'),
        Benzene AS (SELECT * FROM hot_emissions_org WHERE component = 'Benzene'),
        CH4 AS (SELECT * FROM hot_emissions_org WHERE component = 'CH4'),
        CO AS (SELECT * FROM hot_emissions_org WHERE component = 'CO'),
        CO2e AS (SELECT * FROM hot_emissions_org WHERE component = 'CO2e'),
        --CO2rep AS (SELECT * FROM hot_emissions_org WHERE component = 'CO2(rep)'),
        --CO2tot AS (SELECT * FROM hot_emissions_org WHERE component = 'CO2(total)'),
        FC_g AS (SELECT * FROM hot_emissions_org WHERE component = 'FC'),
        FC_MJ AS (SELECT * FROM hot_emissions_org WHERE component = 'FC_MJ'),
        HC AS (SELECT * FROM hot_emissions_org WHERE component = 'HC'),
        N2O AS (SELECT * FROM hot_emissions_org WHERE component = 'N2O'),
        NH3 AS (SELECT * FROM hot_emissions_org WHERE component = 'NH3'),
        NMHC AS (SELECT * FROM hot_emissions_org WHERE component = 'NMHC'),
        NO2 AS (SELECT * FROM hot_emissions_org WHERE component = 'NO2'),
        NOx AS (SELECT * FROM hot_emissions_org WHERE component = 'NOx'),
        Pb AS (SELECT * FROM hot_emissions_org WHERE component = 'Pb'),
        --PM AS (SELECT * FROM hot_emissions_org WHERE component = 'PM'),
        PM10_non_exhaust AS (SELECT * FROM hot_emissions_org WHERE component = 'PM (non-exhaust)'),
        PM25_exhaust AS (SELECT * FROM hot_emissions_org WHERE component = 'PM2.5'),
        PM25_non_exhaust AS (SELECT * FROM hot_emissions_org WHERE component = 'PM2.5 (non-exhaust)'),
        PN AS (SELECT * FROM hot_emissions_org WHERE component = 'PN'),
        SO2 AS (SELECT * FROM hot_emissions_org WHERE component = 'SO2')
SELECT
        hot_emissions_split.cartype,
        hot_emissions_split.year,
        hot_emissions_split.area,
        hot_emissions_split.road_type,
        hot_emissions_split.speed_limit,
        hot_emissions_split.level_of_service,
        bc_exhaust.efa AS bc_exhaust,
        bc_non_exhaust.efa AS bc_non_exhaust,
        benzene.efa AS benzene,
        ch4.efa AS ch4,
        co.efa AS co,
        (SELECT co2_func(cartype => co2e.emconcept, year => co2e.year, co2_wtw => co2e.efa_wtw, fc_g => fc_g.efa, fc_mj => fc_mj.efa)) AS co2_WTW,
        --co2rep.efa AS co2rep,
        --co2rep.tot AS co2tot,
        co2e.efa AS co2_TTW,
        fc_g.efa AS fc_g,
        fc_mj.efa AS fc_mj, 
        hc.efa AS hc,
        n2o.efa AS n2o,
        nh3.efa AS nh3,
        nmhc.efa AS nmhc,
        no2.efa AS no2,
        nox.efa AS nox,
        pb.efa AS pb,
        --pm.efa AS pm,
        pm10_non_exhaust.efa AS pm10_non_exhaust,
        pm25_exhaust.efa AS pm25_exhaust,
        pm25_non_exhaust.efa AS pm25_non_exhaust,        
        pn.efa AS pn,
        so2.efa AS so2,
        evap_running.benzene AS run_benzene,
        evap_running.hc AS run_hc,
        evap_running.nmhc AS run_nmhc,
        evap_running.road_category
FROM hot_emissions_split
        LEFT JOIN bc_exhaust ON bc_exhaust.trafficsit = hot_emissions_split.trafficsit AND bc_exhaust.emconcept = hot_emissions_split.cartype AND bc_exhaust.year = hot_emissions_split.year
        LEFT JOIN bc_non_exhaust ON bc_exhaust.trafficsit = bc_non_exhaust.trafficsit AND bc_exhaust.emconcept = bc_non_exhaust.emconcept AND bc_exhaust.year = bc_non_exhaust.year
        LEFT JOIN benzene ON bc_exhaust.trafficsit = benzene.trafficsit AND bc_exhaust.emconcept = benzene.emconcept AND bc_exhaust.year = benzene.year
        LEFT JOIN ch4 ON bc_exhaust.trafficsit = ch4.trafficsit AND bc_exhaust.emconcept = ch4.emconcept AND bc_exhaust.year = ch4.year
        LEFT JOIN co ON bc_exhaust.trafficsit = co.trafficsit AND bc_exhaust.emconcept = co.emconcept AND bc_exhaust.year = co.year
        LEFT JOIN co2e ON bc_exhaust.trafficsit = co2e.trafficsit AND bc_exhaust.emconcept = co2e.emconcept AND bc_exhaust.year = co2e.year
        --LEFT JOIN co2rep ON bc_exhaust.trafficsit = co2rep.trafficsit AND bc_exhaust.emconcept = co2rep.emconcept AND bc_exhaust.year = co2rep.year
        --LEFT JOIN co2tot ON bc_exhaust.trafficsit = co2tot.trafficsit AND bc_exhaust.emconcept = co2tot.emconcept AND bc_exhaust.year = co2tot.year
        LEFT JOIN fc_g ON bc_exhaust.trafficsit = fc_g.trafficsit AND bc_exhaust.emconcept = fc_g.emconcept AND bc_exhaust.year = fc_g.year
        LEFT JOIN fc_mj ON bc_exhaust.trafficsit = fc_mj.trafficsit AND bc_exhaust.emconcept = fc_mj.emconcept AND bc_exhaust.year = fc_mj.year
        LEFT JOIN hc ON bc_exhaust.trafficsit = hc.trafficsit AND bc_exhaust.emconcept = hc.emconcept AND bc_exhaust.year = hc.year
        LEFT JOIN n2o ON bc_exhaust.trafficsit = n2o.trafficsit AND bc_exhaust.emconcept = n2o.emconcept AND bc_exhaust.year = n2o.year
        LEFT JOIN nh3 ON bc_exhaust.trafficsit = nh3.trafficsit AND bc_exhaust.emconcept = nh3.emconcept AND bc_exhaust.year = nh3.year            
        LEFT JOIN nmhc ON bc_exhaust.trafficsit = nmhc.trafficsit AND bc_exhaust.emconcept = nmhc.emconcept AND bc_exhaust.year = nmhc.year
        LEFT JOIN no2 ON bc_exhaust.trafficsit = no2.trafficsit AND bc_exhaust.emconcept = no2.emconcept AND bc_exhaust.year = no2.year
        LEFT JOIN nox ON bc_exhaust.trafficsit = nox.trafficsit AND bc_exhaust.emconcept = nox.emconcept AND bc_exhaust.year = nox.year
        LEFT JOIN pb ON bc_exhaust.trafficsit = pb.trafficsit AND bc_exhaust.emconcept = pb.emconcept AND bc_exhaust.year = pb.year
        --LEFT JOIN pm ON bc_exhaust.trafficsit = pm.trafficsit AND bc_exhaust.emconcept = pm.emconcept AND bc_exhaust.year = pm.year                      
        LEFT JOIN pm10_non_exhaust ON bc_exhaust.trafficsit = pm10_non_exhaust.trafficsit AND bc_exhaust.emconcept = pm10_non_exhaust.emconcept AND bc_exhaust.year = pm10_non_exhaust.year
        LEFT JOIN pm25_exhaust ON bc_exhaust.trafficsit = pm25_exhaust.trafficsit AND bc_exhaust.emconcept = pm25_exhaust.emconcept AND bc_exhaust.year = pm25_exhaust.year
        LEFT JOIN pm25_non_exhaust ON bc_exhaust.trafficsit = pm25_non_exhaust.trafficsit AND bc_exhaust.emconcept = pm25_non_exhaust.emconcept AND bc_exhaust.year = pm25_non_exhaust.year
        LEFT JOIN pn ON bc_exhaust.trafficsit = pn.trafficsit AND bc_exhaust.emconcept = pn.emconcept AND bc_exhaust.year = pn.year
        LEFT JOIN so2 ON bc_exhaust.trafficsit = so2.trafficsit AND bc_exhaust.emconcept = so2.emconcept AND bc_exhaust.year = so2.year
        LEFT JOIN evap_running ON hot_emissions_split.cartype = evap_running.cartype AND hot_emissions_split.year = evap_running.year AND
        CASE WHEN hot_emissions_split.road_type IN ('MW-City', 'MW-Nat.', 'Semi-MW') THEN evap_running.road_category = 'MW'
             ELSE hot_emissions_split.area = evap_running.road_category
             END
ORDER BY year, area, hot_emissions_split.road_type, speed_limit, level_of_service, 
        CASE WHEN hot_emissions_split.cartype = 'Gasoline' THEN 1
             WHEN hot_emissions_split.cartype = 'Diesel' THEN 2
             WHEN hot_emissions_split.cartype = 'PHEV' THEN 3
             WHEN hot_emissions_split.cartype = 'EV' THEN 4
        END;
DELETE FROM hot_emissions WHERE speed_limit = 130 OR road_type IN ('Distr-sin.', 'Local-sin.');

CREATE INDEX IF NOT EXISTS hot_emissions_year_idx ON public.hot_emissions(year);
CREATE INDEX IF NOT EXISTS hot_emissions_cartype_idx ON public.hot_emissions(cartype);
CREATE INDEX IF NOT EXISTS hot_emissions_area_idx ON public.hot_emissions(area);
CREATE INDEX IF NOT EXISTS hot_emissions_road_type_idx ON public.hot_emissions(road_type);
CREATE INDEX IF NOT EXISTS hot_emissions_speed_limit_idx ON public.hot_emissions(speed_limit);
CREATE INDEX IF NOT EXISTS hot_emissions_level_of_service_idx ON public.hot_emissions(level_of_service);

SELECT * FROM hot_emissions;

DROP TABLE IF EXISTS hot_emissions_org, los_org; -- Here all intermediate hot emission factor tables are dropped
*/

------------------------------------ Scenario specific calculations ----------------------------------------------------------------------------------------------------------------------------


SET SEARCH_PATH TO reference_2019;
--SET SEARCH_PATH TO conservative;
--SET SEARCH_PATH TO optimistic_PHEV;
--SET SEARCH_PATH TO optimistic_EV;
--SET SEARCH_PATH TO EV_only;

/*
DROP TABLE IF EXISTS individualstats_imp;
CREATE TABLE individualstats_imp AS
SELECT
        CAST(individualstats.id AS INTEGER),
        individualstats.homezone,
        zones_by_municipality.municipality,
        individualstats.cartype,
        individualstats.numberoftours,
        individualstats.numberoftrips,
        individualstats.numberofpttrips,
        individualstats.cardistance,
        individualstats.cartime,
        individualstats.totaltraveltime,
        individualstats.isworking,
        individualstats.housing,
        CASE WHEN random() < 0.5 THEN TRUE ELSE FALSE END AS garage, --Every other car is assigned a garage        
        simulationok,
        scaper_agents.antal_bilar,
        scaper_agents.gasoline,
        scaper_agents.diesel,
        scaper_agents.phev,
        scaper_agents.ev,
        scaper_agents.hh_adults,
        scaper_agents.hh_children,
        scaper_agents.small_children
FROM individualstats
LEFT JOIN public.zones_by_municipality
        ON individualstats.homezone = zones_by_municipality.zone_id
LEFT JOIN scaper_agents
        ON CAST(individualstats.id AS INTEGER) = scaper_agents.agent_id;

--SELECT * FROM individualstats_imp LIMIT 1000; 


DROP TABLE IF EXISTS parking_driving_times;
CREATE TABLE parking_driving_times AS
SELECT
        vehicle_id,
        CASE WHEN mov_type = 'enter'
                THEN 'driving'
                ELSE 'parking'
        END AS driving_parking,
        CASE WHEN mov_type = 'enter'
                THEN start_time
                ELSE end_time --The start_time of any parking period is the end_time of the previous driving period
        END AS start_time,
        CASE WHEN mov_type = 'enter'
                THEN LEAD(end_time) OVER (PARTITION BY vehicle_id ORDER BY start_time, end_time) --The end_time of any driving period is the end_time of the last "link_movement" of that driving period
                ELSE LEAD(start_time) OVER (PARTITION BY vehicle_id ORDER BY start_time, end_time) --The end_time of any parking period is the start_time of the next driving period
        END AS end_time
FROM link_movement
WHERE mov_type IN ('enter', 'leave');

--SELECT * FROM parking_driving_times LIMIT 1000;


DROP TABLE IF EXISTS parking_times; 
CREATE TABLE parking_times AS --For cars out driving, this table gives the parking duration of the previous parking period
SELECT
        vehicle_id,
        driving_parking,
        start_time,
        end_time,
        CASE WHEN driving_parking = 'driving'
                THEN LAG(end_time) OVER (PARTITION BY vehicle_id ORDER BY start_time, end_time) - LAG(start_time) OVER (PARTITION BY vehicle_id ORDER BY start_time, end_time)
                ELSE NULL
        END AS parking_duration,
        ROW_NUMBER() OVER (PARTITION BY vehicle_id, driving_parking ORDER BY start_time, end_time) AS trip_number
FROM parking_driving_times;

DELETE FROM parking_times WHERE driving_parking = 'parking';
ALTER TABLE parking_times DROP COLUMN driving_parking;
UPDATE parking_times SET parking_duration = '12:00:00' WHERE trip_number = 1; --Assumption of 12 hours parking time for the first trip of the day (without assumption parking_duration would be NULL)


--SELECT * FROM parking_times ORDER BY vehicle_id, start_time LIMIT 1000;


DROP TABLE IF EXISTS link_movement_links; --5 min 16 s
CREATE TABLE link_movement_links AS
SELECT
        CAST(link_movement.vehicle_id AS INTEGER),
        individualstats_imp.municipality,
        individualstats_imp.homezone,
        individualstats_imp.cartype,
        individualstats_imp.garage,
        link_movement.mov_type, --enter/enroute/leave
        parking_times.trip_number,
        CASE
                WHEN individualstats_imp.garage = TRUE AND parking_times.trip_number = 1 THEN
                        '20'
                ELSE
                        'average'
        END AS temperature,
        parking_times.parking_duration,
        link_movement.start_time,
        link_movement.end_time,
        EXTRACT(EPOCH FROM (link_movement.end_time - link_movement.start_time)) AS duration,
        CAST(link_movement.link_id AS INTEGER),                
        links.length/1000 AS length, --length in km        
        (SUM(links.length) OVER (PARTITION BY parking_times.vehicle_id, parking_times.trip_number ORDER BY link_movement.start_time))/1000 AS trip_distance,
        links.length/EXTRACT(EPOCH FROM(link_movement.end_time - link_movement.start_time))*3.6 as actual_speed, --1 m/s = 3.6 km/h
        links.area,
        links.road_type,
        links.speed_limit,
        los.level_of_service,
        los.lower_v_bound,
        los.upper_v_bound,
        links.capacity,
        links.permlanes,
        links.geom  
FROM link_movement
LEFT JOIN individualstats_imp
        ON CAST(link_movement.vehicle_id AS INTEGER)  = individualstats_imp.id
LEFT JOIN public.links
        ON CAST(link_movement.link_id AS INTEGER) = links.link_id
LEFT JOIN parking_times
        ON link_movement.vehicle_id = parking_times.vehicle_id
        AND link_movement.start_time >= parking_times.start_time
        AND link_movement.end_time <= parking_times.end_time
LEFT JOIN public.los
        ON links.area = los.area
        AND links.road_type = los.road_type
        AND links.speed_limit = los.speed_limit
        AND links.length/EXTRACT(EPOCH FROM (link_movement.end_time - link_movement.start_time))*3.6 >= los.lower_v_bound 
        AND links.length/EXTRACT(EPOCH FROM (link_movement.end_time - link_movement.start_time))*3.6 < los.upper_v_bound
WHERE
        link_movement.vehicle_id NOT LIKE 'Veh%'
        AND EXTRACT(EPOCH FROM (link_movement.end_time - link_movement.start_time)) > 0
        AND link_movement.mov_type != 'enter'        
ORDER BY CAST(link_movement.vehicle_id AS INTEGER), link_movement.start_time;
--DELETE FROM link_movement_links WHERE mov_type = 'enter' OR EXTRACT(EPOCH FROM(end_time - start_time)) <= 0;

CREATE INDEX IF NOT EXISTS link_movement_links_vehicle_id_idx ON link_movement_links(vehicle_id);
CREATE INDEX IF NOT EXISTS link_movement_links_municipality_idx ON link_movement_links(municipality);
CREATE INDEX IF NOT EXISTS link_movement_links_cartype_idx ON link_movement_links(cartype);
CREATE INDEX IF NOT EXISTS link_movement_links_trip_number_idx ON link_movement_links(trip_number);
CREATE INDEX IF NOT EXISTS link_movement_links_temperature_idx ON link_movement_links(temperature);
CREATE INDEX IF NOT EXISTS link_movement_links_parking_duration_idx ON link_movement_links(parking_duration);
CREATE INDEX IF NOT EXISTS link_movement_links_start_time_idx ON link_movement_links(start_time);
CREATE INDEX IF NOT EXISTS link_movement_links_end_time_idx ON link_movement_links(end_time);
CREATE INDEX IF NOT EXISTS link_movement_links_area_idx ON link_movement_links(area);
CREATE INDEX IF NOT EXISTS link_movement_links_road_type_idx ON link_movement_links(road_type);
CREATE INDEX IF NOT EXISTS link_movement_links_speed_limit_idx ON link_movement_links(speed_limit);
CREATE INDEX IF NOT EXISTS link_movement_links_level_of_service_idx ON link_movement_links(level_of_service);

--SELECT * FROM link_movement_links LIMIT 1000;


DROP TABLE IF EXISTS cars_per_agent; --Used to calculate the averge number of cars per agent, based on the assumption that cars
CREATE TABLE cars_per_agent AS       --are distributed equally among adult agents in each and every household
SELECT
        id,
        homezone,
        municipality,
        cartype,
        CAST(gasoline AS FLOAT)/CAST(hh_adults AS FLOAT) AS gasoline, --Necessary to cast as float since, for example, each person in a 
        CAST(diesel AS FLOAT)/CAST(hh_adults AS FLOAT) AS diesel,     --two person household, on average, might own 0.5 cars
        CAST(phev AS FLOAT)/CAST(hh_adults AS FLOAT) AS phev,
        CAST(ev AS FLOAT)/CAST(hh_adults AS FLOAT) AS ev,
        hh_adults,    
        gasoline AS gasoline_org,
        diesel AS diesel_org,
        phev AS phev_org,
        ev AS ev_org
FROM individualstats_imp
WHERE hh_adults > 0;

--SELECT * FROM cars_per_agent LIMIT 1000; 


DROP TABLE IF EXISTS actual_cars_per_municipality;
CREATE TABLE actual_cars_per_municipality AS
SELECT
        municipality,
        SUM(gasoline) AS gasoline,
        SUM(diesel) AS diesel,
        SUM(PHEV) AS PHEV,
        SUM(EV) AS EV
FROM cars_per_agent
GROUP BY municipality
ORDER BY municipality;

SELECT * FROM actual_cars_per_municipality LIMIT 1000;


DROP TABLE IF EXISTS cars_in_use_check;
CREATE TABLE cars_in_use_check AS
        WITH temp AS (WITH
                gasoline AS (SELECT municipality, 'Gasoline' AS cartype, gasoline AS cars_in_use FROM actual_cars_per_municipality),
                diesel AS (SELECT municipality, 'Diesel' AS cartype, diesel AS cars_in_use FROM actual_cars_per_municipality),
                phev AS (SELECT municipality, 'PHEV' AS cartype, PHEV AS cars_in_use FROM actual_cars_per_municipality),
                ev AS (SELECT municipality, 'EV' AS cartype, EV AS cars_in_use FROM actual_cars_per_municipality)
        SELECT * FROM gasoline
        UNION
        SELECT * FROM diesel
        UNION
        SELECT * FROM phev
        UNION
        SELECT * FROM ev
        ORDER BY municipality, cartype),
        cars_driving_per_municipality AS (
                SELECT 
                        municipality,
                        cartype,
                        COUNT(DISTINCT vehicle_id) AS cars_driving
                FROM link_movement_links
                GROUP BY municipality, cartype)
SELECT
        cars_in_use_per_municipality.scenario,
        temp.municipality,
        temp.cartype,
        temp.cars_in_use AS cars_in_use_unadjusted,
        CASE WHEN temp.cars_in_use > 0
                THEN cars_in_use_per_municipality.cars_in_use/temp.cars_in_use
                ELSE 0
                END AS coefficient,
        cars_in_use_per_municipality.cars_in_use AS cars_in_use_correct,
        cars_driving_per_municipality.cars_driving,
        cars_driving_per_municipality.cars_driving/temp.cars_in_use*100 AS cars_driving_percent,
        municipalities.geom
FROM temp
LEFT JOIN public.cars_in_use_per_municipality
        ON cars_in_use_per_municipality.scenario = 'reference_2019' --reference_2019, conservative, optimistic_PHEV, optimistic_EV, EV_only
        AND cars_in_use_per_municipality.municipality = temp.municipality
        AND cars_in_use_per_municipality.cartype = temp.cartype
LEFT JOIN cars_driving_per_municipality
        ON cars_driving_per_municipality.municipality = temp.municipality
        AND cars_driving_per_municipality.cartype = temp.cartype    
LEFT JOIN public.municipalities
        ON temp.municipality = municipalities.municipality
WHERE temp.municipality IS NOT NULL
ORDER BY municipality, 
         CASE WHEN temp.cartype = 'Gasoline' THEN 1
              WHEN temp.cartype = 'Diesel' THEN 2
              WHEN temp.cartype = 'PHEV' THEN 3
              WHEN temp.cartype = 'EV' THEN 4
        END;

CREATE INDEX IF NOT EXISTS cars_in_use_check_municipality_idx ON cars_in_use_check(municipality);
CREATE INDEX IF NOT EXISTS cars_in_use_check_cartype_idx ON cars_in_use_check(cartype);


--SELECT * FROM cars_in_use_check;


DROP TABLE IF EXISTS agents_hh_grouped; --This table is no longer used
CREATE TABLE agents_hh_grouped AS
SELECT
    hh_id,
    inkomst_konsumtionsenhet,
    hh_adults,
    hh_children,
    antal_bilar,
    gasoline,
    diesel,
    PHEV,
    EV,
    zones_by_municipality.municipality,
    homezone,
    zones_by_municipality.geom
FROM scaper_agents
LEFT JOIN public.zones_by_municipality
        ON scaper_agents.homezone = zones_by_municipality.zone_id
GROUP BY hh_id, inkomst_konsumtionsenhet, hh_adults, hh_children, antal_bilar, gasoline, diesel, PHEV, EV, municipality, geom, homezone;

--SELECT COUNT(DISTINCT hh_id) FROM scaper_agents; --859339 households. Both of these two tables should givethe same number.
--SELECT COUNT(*) FROM agents_hh_grouped;

--SELECT * FROM agents_hh_grouped LIMIT 1000;


DROP TABLE IF EXISTS agents_mn_grouped; --This table is no longer used
CREATE TABLE agents_mn_grouped AS
SELECT
        SUM(gasoline) AS gasoline,
        SUM(diesel) AS diesel,
        SUM(PHEV) AS PHEV,
        SUM(EV) AS EV,
        municipality
FROM agents_hh_grouped
GROUP BY municipality
ORDER BY municipality;

--SELECT * FROM agents_mn_grouped LIMIT 1000;


DROP TABLE IF EXISTS results; --Total execution time: 00:09:40.858
CREATE TABLE results AS
SELECT
        lml.vehicle_id,
        lml.municipality,
        lml.homezone,
        lml.cartype,
        cars_in_use_check.coefficient,
        lml.link_id,
        lml.start_time,
        lml.end_time,
        lml.duration,
        lml.length,
        lml.area,
        lml.road_type, -- Motorway-Nat., Motorway-City, Semi-Motorway, Primary-nat. non-motorway, Primary-city non-motorway, Distributor/Secondary, Distributor/Secondary(sinuous), Local/Collector, Local/Collector(sinuous), Access-residential
        lml.speed_limit,
        hot_emissions.level_of_service,
        --lml.lower_v_bound,
        lml.actual_speed,
        --lml.upper_v_bound,
        lml.trip_number,
        --cold_start.temperature,
        lml.trip_distance,
        --cold_start.lower_p_bound,
        lml.parking_duration,
        --cold_start.upper_p_bound,
        hot_emissions.bc_exhaust*lml.length AS bc_exhaust,
        hot_emissions.bc_non_exhaust*lml.length AS bc_non_exhaust,
        hot_emissions.benzene*lml.length AS benzene,
        hot_emissions.ch4*lml.length AS ch4,
        hot_emissions.co*lml.length AS co,
        hot_emissions.co2_WTW*lml.length AS co2_WTW,
        hot_emissions.co2_TTW*lml.length AS co2_TTW,
        --hot_emissions.fc_g*lml.length AS fc_g,
        --hot_emissions.fc_mj*lml.length AS fc_mj,        
        hot_emissions.hc*lml.length AS hc,
        hot_emissions.nox*lml.length AS nox,
        hot_emissions.n2o*lml.length AS n2o,
        hot_emissions.nh3*lml.length AS nh3,
        hot_emissions.nmhc*lml.length AS nmhc,
        hot_emissions.no2*lml.length AS no2,    
        hot_emissions.pb*lml.length AS pb,
        hot_emissions.pm10_non_exhaust*lml.length AS pm10_non_exhaust,
        hot_emissions.pm25_exhaust*lml.length AS pm25_exhaust,
        hot_emissions.pm25_non_exhaust*lml.length AS pm25_non_exhaust,
        hot_emissions.pn*lml.length AS pn,  
        hot_emissions.so2*lml.length AS so2,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_bc_exhaust
             THEN cold_start.bc_exhaust*(EXP(-cold_start.lambda_bc_exhaust*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_bc_exhaust*lml.trip_distance))
             ELSE 0
             END AS c_bc_exhaust,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_benzene
             THEN cold_start.benzene*(EXP(-cold_start.lambda_benzene*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_benzene*lml.trip_distance))
             ELSE 0
             END AS c_benzene,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_ch4
             THEN cold_start.ch4*(EXP(-cold_start.lambda_ch4*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_ch4*lml.trip_distance))
             ELSE 0
             END AS c_ch4,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_co
             THEN cold_start.co*(EXP(-cold_start.lambda_co*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_co*lml.trip_distance))
             ELSE 0
             END AS c_co,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_co2
             THEN cold_start.co2_wtw*(EXP(-cold_start.lambda_co2*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_co2*lml.trip_distance))
             ELSE 0
             END AS c_co2_wtw,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_co2
             THEN cold_start.co2_ttw*(EXP(-cold_start.lambda_co2*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_co2*lml.trip_distance))
             ELSE 0
             END AS c_co2_ttw,
        --CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_fc
        --      THEN cold_start.fc_g*(EXP(-cold_start.lambda_fc*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_fc*lml.trip_distance))
        --      ELSE 0
        --      END AS c_fc_g,
        --CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_fc
        --      THEN cold_start.fc_mj*(EXP(-cold_start.lambda_fc*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_fc*lml.trip_distance))
        --      ELSE 0
        --      END AS c_fc_mj,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_hc
             THEN cold_start.hc*(EXP(-cold_start.lambda_hc*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_hc*lml.trip_distance)) 
             ELSE 0
             END AS c_hc,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_nox
             THEN cold_start.nox*(EXP(-cold_start.lambda_nox*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_nox*lml.trip_distance))
             ELSE 0
             END AS c_nox,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_nmhc
             THEN cold_start.nmhc*(EXP(-cold_start.lambda_nmhc*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_nmhc*lml.trip_distance))
             ELSE 0
             END AS c_nmhc,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_no2
             THEN cold_start.no2*(EXP(-cold_start.lambda_no2*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_no2*lml.trip_distance))
             ELSE 0
             END AS c_no2,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_pb
             THEN cold_start.pb*(EXP(-cold_start.lambda_pb*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_pb*lml.trip_distance))
             ELSE 0
             END AS c_pb,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_pm25_exhaust
             THEN cold_start.pm25_exhaust*(EXP(-cold_start.lambda_pm25_exhaust*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_pm25_exhaust*lml.trip_distance))
             ELSE 0
             END AS c_pm25_exhaust,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_pn
             THEN cold_start.pn*(EXP(-cold_start.lambda_pn*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_pn*lml.trip_distance))
             ELSE 0
             END AS c_pn,
        CASE WHEN lml.trip_distance - lml.length < -LN(1-0.99)/cold_start.lambda_so2
             THEN cold_start.so2*(EXP(-cold_start.lambda_so2*(lml.trip_distance-lml.length)) - EXP(-cold_start.lambda_so2*lml.trip_distance))
             ELSE 0
             END AS c_so2,
        evap_diurnal.benzene/cars_in_use_check.cars_driving_percent*100 AS diurnal_benzene,
        evap_diurnal.hc/cars_in_use_check.cars_driving_percent*100 AS diurnal_hc,
        evap_diurnal.nmhc/cars_in_use_check.cars_driving_percent*100 AS diurnal_nmhc,
        evap_soak.benzene AS soak_benzene,
        evap_soak.hc AS soak_hc,
        evap_soak.nmhc AS soak_nmhc,        
        hot_emissions.run_benzene*length AS run_benzene,
        hot_emissions.run_hc*length AS run_hc,
        hot_emissions.run_nmhc*length AS run_nmhc,
        lml.geom
FROM link_movement_links AS lml
LEFT JOIN public.hot_emissions
        ON hot_emissions.year = 2019 --The year has to be changed manually to correspond to the scenario year (2019 or 2030)
        AND lml.cartype = hot_emissions.cartype
        AND lml.area = hot_emissions.area
        AND lml.road_type = hot_emissions.road_type
        AND lml.speed_limit = hot_emissions.speed_limit
        AND lml.level_of_service = hot_emissions.level_of_service 
LEFT JOIN public.cold_start
        ON cold_start.year = 2019 --The year has to be changed manually to correspond to the scenario year (2019 or 2030)
        AND lml.temperature = cold_start.temperature
        AND lml.cartype = cold_start.cartype
        AND lml.parking_duration >= cold_start.lower_p_bound
        AND lml.parking_duration < cold_start.upper_p_bound
LEFT JOIN public.evap_diurnal -- g/day   
        ON lml.garage = FALSE
        AND lml.trip_number = 1
        AND lml.trip_distance = lml.length
        AND evap_diurnal.year = 2019 --The year has to be changed manually to correspond to the scenario year (2019 or 2030) AND lml.cartype = evap_diurnal.cartype
        AND lml.cartype = evap_diurnal.cartype
LEFT JOIN public.evap_soak  --g/stop
        ON lml.trip_distance = lml.length
        AND evap_soak.year = 2019 --The year has to be changed manually to correspond to the scenario year (2019 or 2030) AND lml.cartype = evap_diurnal.cartype
        AND lml.cartype = evap_soak.cartype
LEFT JOIN cars_in_use_check
        ON lml.cartype = cars_in_use_check.cartype
        AND lml.municipality = cars_in_use_check.municipality
ORDER BY vehicle_id, start_time;

CREATE INDEX IF NOT EXISTS results_vehicle_id_idx ON results(vehicle_id);
CREATE INDEX IF NOT EXISTS results_municipality_idx ON results(municipality);
CREATE INDEX IF NOT EXISTS results_cartype_idx ON results(cartype);
CREATE INDEX IF NOT EXISTS results_link_id_idx ON results(link_id);
CREATE INDEX IF NOT EXISTS results_start_time_idx ON results(start_time);
CREATE INDEX IF NOT EXISTS results_end_time_idx ON results(end_time);

--SELECT * FROM results LIMIT 1000;


DROP TABLE IF EXISTS results_sum_unweighted;
CREATE TABLE results_sum_unweighted AS --Total execution time: 00:02:57.809
SELECT
        cartype,
        municipality,
        COUNT(DISTINCT vehicle_id) AS cars_driving,
        SUM(length) AS km_driven,
        SUM(bc_exhaust) AS bc_exhaust,
        SUM(bc_non_exhaust) AS bc_non_exhaust,
        SUM(benzene) AS benzene,
        SUM(ch4) AS ch4,                        
        SUM(co) AS co,
        SUM(co2_WTW) AS co2_WTW,
        SUM(co2_TTW) AS co2_TTW,
        SUM(hc) AS hc,
        SUM(nox) AS nox,
        SUM(n2o) AS n2o,
        SUM(nh3) AS nh3,
        SUM(nmhc) AS nmhc,
        SUM(no2) AS no2,    
        SUM(pb) AS pb,
        SUM(pm10_non_exhaust) AS pm10_non_exhaust,
        SUM(pm25_exhaust) AS pm25_exhaust,
        SUM(pm25_non_exhaust) AS pm25_non_exhaust,
        SUM(pn) AS pn,
        SUM(so2) AS so2,
        SUM(c_bc_exhaust) AS c_bc_exhaust,
        SUM(c_benzene) AS c_benzene,
        SUM(c_ch4) AS c_ch4,
        SUM(c_co) AS c_co,
        SUM(c_co2_wtw) AS c_co2_wtw,        
        SUM(c_co2_ttw) AS c_co2_ttw,
        SUM(c_hc) AS c_hc,
        SUM(c_nox) AS c_nox,
        SUM(c_nmhc) AS c_nmhc,
        SUM(c_no2) AS c_no2,
        SUM(c_pb) AS c_pb,
        SUM(c_pm25_exhaust) AS c_pm25_exhaust,
        SUM(c_pn) AS c_pn,
        SUM(c_so2) AS c_so2,
        SUM(diurnal_benzene) AS diurnal_benzene,
        SUM(diurnal_hc) AS diurnal_hc,
        SUM(diurnal_nmhc) AS diurnal_nmhc,
        SUM(soak_benzene) AS soak_benzene,
        SUM(soak_hc) AS soak_hc,
        SUM(soak_nmhc) AS soak_nmhc,
        SUM(run_benzene) AS run_benzene,
        SUM(run_hc) AS run_hc,
        SUM(run_nmhc) AS run_nmhc     
FROM results
GROUP BY municipality, cartype
ORDER BY municipality, 
         CASE WHEN cartype = 'Gasoline' THEN 1
              WHEN cartype = 'Diesel' THEN 2
              WHEN cartype = 'PHEV' THEN 3
              WHEN cartype = 'EV' THEN 4
        END;

--SELECT * FROM results_sum_unweighted;


--SELECT --Calculations of coefficient so that the total emissions of PM2.5 and PM10 equal 0.19548308200725 g/km (which is the value used by Trafikverket)
--        0.20/(SUM(pm10_non_exhaust)/SUM(km_driven)) AS adjustment --7.160584772031272 --6.998865901054273 --6.985666522784393 --6.727454524684055 --6.837397323362449 --6.666745589998476 --6.6267589060454375 --7.073300975047489 --7.192150801377438
--FROM reference_2019.results_sum_unweighted --This should be the reference scenario for 2019
--WHERE cartype IS NOT NULL;


DROP TABLE IF EXISTS results_sum; --The unit in this table is kg, except for km_driven and pn, not grams as in results table
CREATE TABLE results_sum AS
SELECT
        cars_in_use_check.scenario,
        results_sum_unweighted.cartype,
        results_sum_unweighted.municipality,
        cars_in_use_check.cars_in_use_unadjusted,
        cars_in_use_check.coefficient,
        cars_in_use_check.cars_in_use_correct AS cars_in_use, --The same as cars_in_use_unadjusted*coefficient
        results_sum_unweighted.cars_driving*coefficient AS cars_driving,
        results_sum_unweighted.cars_driving*coefficient/(cars_in_use_check.cars_in_use_correct)*100 AS cars_driving_percent,
        km_driven*coefficient*365.25 AS km_driven,               --Exception: Since length is already measured in km, there is no conversion from m to km (i.e. no divison by 1000)
        km_driven*coefficient*365.25/(cars_in_use_check.cars_in_use_correct) AS avg_km_driven, --Average driving distance for all cars
        bc_exhaust*coefficient*0.36525 AS bc_exhaust,           --coefficient * 0.36525 = coefficient / 1000 * 365.25
        bc_non_exhaust*coefficient*7.160584772031272*0.36525 AS bc_non_exhaust,   --conversion from g to kg: division by 1000
        benzene*coefficient*0.36525 AS benzene,                 --adjusting for that traffic is only simulated for a single day: multiplication with 335
        ch4*coefficient*0.36525 AS ch4,
        co*coefficient*0.36525 AS co,
        co2_wtw*coefficient*0.36525 AS co2_wtw,
        co2_ttw*coefficient*0.36525 AS co2_ttw,
        hc*coefficient*0.36525 AS hc,
        nox*coefficient*0.36525 AS nox,
        n2o*coefficient*0.36525 AS n2o,
        nh3*coefficient*0.36525 AS nh3,
        nmhc*coefficient*0.36525 AS nmhc,
        no2*coefficient*0.36525 AS no2,
        pb*coefficient*0.36525 AS pb,
        pm10_non_exhaust*coefficient*7.160584772031272*0.36525 AS pm10_non_exhaust,
        pm25_exhaust*coefficient*0.36525 AS pm25_exhaust,
        pm25_non_exhaust*coefficient*7.160584772031272*0.36525 AS pm25_non_exhaust,
        pn*coefficient*365.25 AS pn, --Exception: Since particle number, pn, is not measured in weight, there is no conversion from g to kg (i.e. no divison by 1000)
        so2*coefficient*0.36525 AS so2,
        c_bc_exhaust*coefficient*0.36525 AS c_bc_exhaust,
        c_benzene*coefficient*0.36525 AS c_benzene,
        c_ch4*coefficient*0.36525 AS c_ch4,
        c_co*coefficient*0.36525 AS c_co,
        c_co2_wtw*coefficient*0.36525 AS c_co2_wtw,
        c_co2_ttw*coefficient*0.36525 AS c_co2_ttw,
        c_hc*coefficient*0.36525 AS c_hc,
        c_nox*coefficient*0.36525 AS c_nox,
        c_nmhc*coefficient*0.36525 AS c_nmhc,
        c_no2*coefficient*0.36525 AS c_no2,
        c_pb*coefficient*0.36525 AS c_pb,
        c_pm25_exhaust*coefficient*0.36525 AS c_pm25_exhaust,
        c_pn*coefficient*0.36525 AS c_pn,
        c_so2*coefficient*0.36525 AS c_so2,
        diurnal_benzene*coefficient*0.36525 AS diurnal_benzene,
        diurnal_hc*coefficient*0.36525 AS diurnal_hc,
        diurnal_nmhc*coefficient*0.36525 AS diurnal_nmhc,
        soak_benzene*coefficient*0.36525 AS soak_benzene,
        soak_hc*coefficient*0.36525 AS soak_hc,
        soak_nmhc*coefficient*0.36525 AS soak_nmhc,
        run_benzene*coefficient*0.36525 AS run_benzene,
        run_hc*coefficient*0.36525 AS run_hc,
        run_nmhc*coefficient*0.36525 AS run_nmhc
FROM results_sum_unweighted
LEFT JOIN cars_in_use_check
        ON results_sum_unweighted.cartype = cars_in_use_check.cartype
        AND results_sum_unweighted.municipality = cars_in_use_check.municipality
WHERE results_sum_unweighted.municipality IS NOT NULL;

--SELECT * FROM results_sum;


DROP TABLE IF EXISTS results_by_link;  --Table gives the average emissions per kilometer for each link and pollutant, to enable visualization in QGIS
CREATE TABLE results_by_link AS
SELECT
    --vehicle_id,
    --homezone,
    --municipality,
    --cartype,
    link_id,
    --start_time,
    --duration,
    length,
    area,
    road_type,
    speed_limit,
    SUM(coefficient) AS flow, --adjusted car flow
    COUNT(vehicle_id)*10 AS unadjusted_flow,
    --level_of_service,
    --actual_speed,
    --trip_number,
    --trip_distance,
    --parking_duration,
    SUM(bc_exhaust*coefficient)/length AS bc_exhaust,
    SUM(bc_non_exhaust*coefficient)*7.160584772031272/length AS bc_non_exhaust,
    SUM(benzene*coefficient)/length AS benzene,
    SUM(ch4*coefficient)/length AS ch4,
    SUM(co*coefficient)/length AS co,
    SUM(co2_wtw*coefficient)/length AS co2_wtw,
    SUM(co2_ttw*coefficient)/length AS co2_ttw,
    SUM(hc*coefficient)/length AS hc,
    SUM(nox*coefficient)/length AS nox,
    SUM(n2o*coefficient)/length AS n2o,
    SUM(nh3*coefficient)/length AS nh3,
    SUM(nmhc*coefficient)/length AS nmhc,
    SUM(no2*coefficient)/length AS no2,
    SUM(pb*coefficient)/length AS pb,
    SUM(pm10_non_exhaust*coefficient)*7.160584772031272/length AS pm10_non_exhaust,
    SUM(pm25_exhaust*coefficient)/length AS pm25_exhaust,
    SUM(pm25_non_exhaust*coefficient)*7.160584772031272/length AS pm25_non_exhaust,
    SUM(pn*coefficient)/length AS pn,
    SUM(so2*coefficient)/length AS so2,
    SUM(c_bc_exhaust*coefficient)/length AS c_bc_exhaust,
    SUM(c_benzene*coefficient)/length AS c_benzene,
    SUM(c_ch4*coefficient)/length AS c_ch4,
    SUM(c_co*coefficient)/length AS c_co,
    SUM(c_co2_wtw*coefficient)/length AS c_co2_wtw,    
    SUM(c_co2_ttw*coefficient)/length AS c_co2_ttw,
    SUM(c_hc*coefficient)/length AS c_hc,
    SUM(c_nox*coefficient)/length AS c_nox,
    SUM(c_nmhc*coefficient)/length AS c_nmhc,
    SUM(c_no2*coefficient)/length AS c_no2,
    SUM(c_pb*coefficient)/length AS c_pb,
    SUM(c_pm25_exhaust*coefficient)/length AS c_pm25_exhaust,
    SUM(c_pn*coefficient)/length AS c_pn,
    SUM(c_so2*coefficient)/length AS c_so2,
    SUM(diurnal_benzene*coefficient)/length AS diurnal_benzene,
    SUM(diurnal_hc*coefficient)/length AS diurnal_hc,
    SUM(diurnal_nmhc*coefficient)/length AS diurnal_nmhc,
    SUM(soak_benzene*coefficient)/length AS soak_benzene,
    SUM(soak_hc*coefficient)/length AS soak_hc,
    SUM(soak_nmhc*coefficient)/length AS soak_nmhc,
    SUM(run_benzene*coefficient)/length AS run_benzene,
    SUM(run_hc*coefficient)/length AS run_hc,
    SUM(run_nmhc*coefficient)/length AS run_nmhc,
    geom
FROM results
GROUP BY link_id, geom, length, area, road_type, speed_limit
ORDER BY link_id;


--SELECT * FROM results_by_link LIMIT 1000;
*/
DROP TABLE IF EXISTS parking_driving_times;
SET SEARCH_PATH TO public;

-------------------------------------- Calculations to summarize results of all scenarios ------------------------------------------------------------------------------------------------------------------

/*
DROP TABLE IF EXISTS cars_in_use_check;
CREATE TABLE cars_in_use_check AS
SELECT * FROM reference_2019.cars_in_use_check
UNION ALL
SELECT * FROM conservative.cars_in_use_check
UNION ALL
SELECT * FROM optimistic_PHEV.cars_in_use_check
UNION ALL
SELECT * FROM optimistic_EV.cars_in_use_check
UNION ALL
SELECT * FROM EV_only.cars_in_use_check;

--SELECT * FROM cars_in_use_check;
*/
/*
SELECT --Total number of cars in use per scenario
        scenario,
        ROUND(CAST(SUM(cars_in_use_unadjusted) AS NUMERIC), 0) AS cars_in_use_unadjusted,
        ROUND(CAST(SUM(cars_in_use_correct) AS NUMERIC), 0) AS cars_in_use_correct,
        ROUND(CAST(SUM(cars_in_use_unadjusted)*10/SUM(cars_in_use_correct)*100-100 AS NUMERIC), 2) AS diff_percent
FROM cars_in_use_check
GROUP BY scenario
ORDER BY 
        CASE WHEN scenario = 'reference_2019' THEN 1
             WHEN scenario = 'conservative' THEN 2
             WHEN scenario = 'optimistic_PHEV' THEN 3
             WHEN scenario = 'optimistic_EV' THEN 4
             WHEN scenario = 'EV_only' THEN 5
         END;
*/
/*
SELECT --Number of cars in use per cartype and scenario
        scenario,
        municipality,
        cartype,
        ROUND(CAST(SUM(cars_in_use_unadjusted) AS NUMERIC), 0) AS cars_in_use_unadjusted,
        ROUND(CAST(SUM(cars_in_use_correct) AS NUMERIC), 0) AS cars_in_use_correct,
        CASE WHEN SUM(cars_in_use_unadjusted) > 0
                THEN ROUND(CAST(SUM(cars_in_use_unadjusted)*10/SUM(cars_in_use_correct)*100-100 AS NUMERIC), 2) 
                ELSE 0
        END AS diff_percent
FROM cars_in_use_check
GROUP BY scenario, cartype, municipality
ORDER BY
        CASE WHEN scenario = 'reference_2019' THEN 1
             WHEN scenario = 'conservative' THEN 2
             WHEN scenario = 'optimistic_PHEV' THEN 3
             WHEN scenario = 'optimistic_EV' THEN 4
             WHEN scenario = 'EV_only' THEN 5
        END, municipality,
        CASE WHEN cartype = 'Gasoline' THEN 1
             WHEN cartype = 'Diesel' THEN 2
             WHEN cartype = 'PHEV' THEN 3
             WHEN cartype = 'EV' THEN 4
        END;
*/
/*
DROP TABLE IF EXISTS results_sum;
CREATE TABLE results_sum AS
SELECT * FROM reference_2019.results_sum
UNION ALL
SELECT * FROM conservative.results_sum
UNION ALL
SELECT * FROM optimistic_PHEV.results_sum
UNION ALL
SELECT * FROM optimistic_EV.results_sum
UNION ALL
SELECT * FROM EV_only.results_sum;

--SELECT * FROM results_sum;
*/
--/*
SELECT
        scenario,
        --cartype,
        --municipality,
        ROUND(CAST(SUM(cars_in_use_unadjusted) AS NUMERIC), 0) AS cars_in_use_unadjusted,
        ROUND(CAST(SUM(cars_in_use)/SUM(cars_in_use_unadjusted) AS NUMERIC), 2) AS coefficient,
        ROUND(CAST(SUM(cars_in_use) AS NUMERIC), 0) AS cars_in_use,
        ROUND(CAST(SUM(cars_driving) AS NUMERIC), 0) AS cars_driving,
        ROUND(CAST(SUM(cars_driving)/SUM(cars_in_use)*100 AS NUMERIC), 2) AS cars_driving_percent,
        ROUND(CAST(SUM(km_driven)/1000000 AS NUMERIC), 10) AS million_km_driven, --11,629.50684 million km = 124,300 km/(car*year) * 935,865 cars / 1,000,000
        ROUND(CAST(SUM(km_driven)/SUM(cars_in_use) AS NUMERIC), 0) AS avg_km_driven, --12,430 km is the 2019 average for Stockholm County. However, this number should be higher as not all cars are driven on any given day
        SUM(bc_exhaust) AS bc_exhaust,
        SUM(bc_non_exhaust) AS bc_non_exhaust,
        SUM(benzene) AS benzene,
        SUM(ch4) AS ch4,
        SUM(co) AS co,
        SUM(co2_wtw) AS co2_wtw,        
        SUM(co2_ttw) AS co2_ttw,
        SUM(hc) AS hc,
        SUM(nox) AS nox,
        SUM(n2o) AS n2o,
        SUM(nh3) AS nh3,
        SUM(nmhc) AS nmhc,
        SUM(no2) AS no2,
        SUM(pb) AS pb,
        SUM(pm10_non_exhaust) AS pm10_non_exhaust,
        SUM(pm25_exhaust) AS pm25_exhaust,
        SUM(pm25_non_exhaust) AS pm25_non_exhaust,
        SUM(pn) AS pn,
        SUM(so2) AS so2,
        SUM(c_bc_exhaust) AS c_bc_exhaust,
        SUM(c_benzene) AS c_benzene,
        SUM(c_ch4) AS c_ch4,
        SUM(c_co) AS c_co,
        SUM(c_co2_wtw) AS c_co2_wtw,        
        SUM(c_co2_ttw) AS c_co2_ttw,
        SUM(c_hc) AS c_hc,
        SUM(c_nox) AS c_nox,
        SUM(c_nmhc) AS c_nmhc,
        SUM(c_no2) AS c_no2,
        SUM(c_pb) AS c_pb,
        SUM(c_pm25_exhaust) AS c_pm25_exhaust,
        SUM(c_pn) AS c_pn,
        SUM(c_so2) AS c_so2,
        SUM(diurnal_benzene) AS diurnal_benzene,
        SUM(diurnal_hc) AS diurnal_hc,
        SUM(diurnal_nmhc) AS diurnal_nmhc,
        SUM(soak_benzene) AS soak_benzene,
        SUM(soak_hc) AS soak_hc,
        SUM(soak_nmhc) AS soak_nmhc,
        SUM(run_benzene) AS run_benzene,
        SUM(run_hc) AS run_hc,
        SUM(run_nmhc) AS run_nmhc
FROM results_sum
GROUP BY scenario--, cartype
ORDER BY
        CASE WHEN scenario = 'reference_2019' THEN 1
             WHEN scenario = 'conservative' THEN 2
             WHEN scenario = 'optimistic_PHEV' THEN 3
             WHEN scenario = 'optimistic_EV' THEN 4
             WHEN scenario = 'EV_only' THEN 5
        END;--,
        --CASE WHEN cartype = 'Gasoline' THEN 1
        --     WHEN cartype = 'Diesel' THEN 2
        --     WHEN cartype = 'PHEV' THEN 3
        --     WHEN cartype = 'EV' THEN 4
        --END;
--*/
/*
SELECT  --CO2 emissions in megatons
        (SELECT ROUND(CAST(SUM(km_driven)/SUM(cars_in_use) AS NUMERIC), 0) FROM results_sum WHERE scenario = 'reference_2019') AS avg_km,
        12430 AS obs_avg_km, --12,430 km is the 2019 average driving distance per car in Stockholm County
        (SELECT ROUND(CAST(SUM(km_driven)/SUM(cars_in_use)/12430*100 AS NUMERIC), 2) FROM results_sum WHERE scenario = 'reference_2019') AS "%_of_obs",
        (SELECT ROUND(CAST(SUM(co2_ttw)/1000000 AS NUMERIC), 2) FROM results_sum WHERE scenario = 'reference_2019') AS co2_ttw,
        (SELECT ROUND(CAST(SUM(c_co2_ttw)/1000000 AS NUMERIC), 2) FROM results_sum WHERE scenario = 'reference_2019') AS c_co2_ttw,
        (SELECT ROUND(CAST((SUM(co2_ttw)+SUM(c_co2_ttw))/1000000 AS NUMERIC), 2) FROM results_sum WHERE scenario = 'reference_2019') AS tot_co2_ttw,
        ROUND(10081.4*0.203165611514924, 2) AS est_co2, -- Total emissions from passenger cars in Sweden in 2019 multiplied with the share of veicle-km driven in Stockholm County in 2018
        (SELECT ROUND(CAST((SUM(co2_ttw)+SUM(c_co2_ttw))/1000000 AS NUMERIC)/(10007*0.203165611514924)*100, 2) FROM results_sum WHERE scenario = 'reference_2019') AS "%_of_estimate";
*/