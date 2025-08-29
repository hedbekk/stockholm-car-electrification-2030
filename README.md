# KTH Thesis Project

**Thesis Title:**  
*The Potential of Electrification in Reducing Emissions from Passenger Cars in Stockholm County by 2030:  
A Modeling Study of the Potential of Plug-In Hybrids and All-Electric Cars in Reducing Greenhouse Gas Emissions and Air Pollution*

📄 Full report available at: [DiVA Portal](https://www.diva-portal.org/smash/record.jsf?pid=diva2%3A1578459&dswid=7135)


## Repository Contents

The repository is organized into four subfolders:

<h3>CSVs <span style="font-weight:normal">– Input data and reference layers for SQL and QGIS</span></h3>

- **`cars_in_use_per_municipality.csv`** – Number of EVs, PHEV, gasoline and diesel vehicles in use per municipality in each of the modeled scenarios. Used in `Main.sql` for weighting emissions to adjust for inconsistencies in Scaper output data.

- **`cold_start.csv`** – Values used to calculate cold-start emissions as exponentially decreasing functions of driving distance, as calculated in `Cold start emission modeling.xlsm`. Used in `Main.sql`.

- **`emme_kommun.csv`** – Used in `Main.sql` to link Scaper zones to their municipalities

- **`evaporation_diurnal.csv`** – Emission factors from HBEFA for diurnal evaporation losses (fuel evaporation from parked vehicles caused by daily temperature changes). Used in `Main.sql`.

- **`evaporation_running.csv`** – Emission factors from HBEFA for running losses (fuel evaporation while driving). Used in `Main.sql`.

- **`evaporation_soak.csv`** – Emission factors from HBEFA for hot soak losses (fuel evaporation immediately after parking a warm vehicle). Used in `Main.sql`.

- **`HBEFA_hot.csv`** – Hot emission factors from HBEFA. Used in `Main.sql`.

- **`hbefa_cold.csv`** – Cold-start emission factors from HBEFA. Imported and reformatted in Main.sql, then exported for use in `Cold start emission modeling.xlsm`, where they are converted into exponentially decreasing functions of driving distance.

- **`los.csv`** – Speed thresholds that define level-of-service classes (Freeflow, Heavy, Satur., St+Go and St+Go2) by rural/urban area, road type and speed limit. Used in `Main.sql` to map observed link speeds to a LoS class and select the corresponding HBEFA hot emission factors.

- **`scb_kommun.csv`** – Municipality codes, populations and boundary coordinates from Statistics Sweden (SCB). Used in Main.sql and `Transports.gqz`.

- **`sverige_tz_epsg3006.csv`** – Transport model zone polygons for Sweden. Used in `Main.sql` to link zones to municipalities.

- **`time_5.csv`** – Time intervals in 5-minute steps, used in `Scaper output checks.sql` for high-resolution traffic flow checks.


<h3>Excel <span style="font-weight:normal">– Workbooks for scenario building, emission factor conversions, diagnostics and figures</span></h3>

- **`Cold start emission modeling.xlsm`** – Used for converting 1,476 cold-start emission factors, specified in grams per start for the predefined driving distances 0.5, 1.5, 2.5, 3.5, 4.5 and 30 km, into continuous exponential functions of driving distance. Automated using VBA and Excel Solver, with least squares fitting.

- **`Scaper output diagnostics.xlsx`** – Visualizations of anomalies and quality issues in Scaper outputs (e.g. cars driving 10× above the speed limit and accumulation of traffic during the 24h simulation period). Based on the outputs from `Scaper output checks.sql`.

- **`Scenario results.xlsx`** – Visualizations of how total driving distance and emissions of CO₂, NOx, NMHC, PM₁₀ and PM₂.₅ would change under each scenario, along with more detailed tabulated data. Also includes additional figures that were not included in the final report. Based on the outputs from `Main.sql`.
  
- **`Scenarios.xlsm`** – Modelling of municipality-level scenarios for 2030 (population and car fleet composition). The scenarios are based exclusively on official population projections and historic car sales and ownership data from 2010–2019, which are also included in the workbook.

- **`Sweden emission statistics 1990-2019.xlsx`** – Visualizations of historic emissions of CO₂, NOx, NMHC, PM₁₀ and PM₂.₅ in Sweden between 1990 and 2019, along with the sector-wise distribution of CO₂ emissions in 2019.


<h3>GIS <span style="font-weight:normal">– QGIS project for spatial analysis and visualization</span></h3>

- **`Transports.gqz`** – Used for visualizing the road network, traffic flow and the geographical distribution of emissions.

<h3>SQL <span style="font-weight:normal">– Scripts for emissions modeling and data validation</span></h3>

- **`Main.sql`** – Pipeline for calculating emissions of 17 pollutants, including CO₂, NOx, NMHC, PM₁₀ and PM₂.₅, from Scaper outputs. Calculations are performed vehicle by vehicle and road link by road link, without pre-aggregating traffic flows, using HBEFA emission factors for both hot and cold start emissions.

- **`PM visualization.sql`** – SQL script for spatially allocating PM₂.₅ emissions from road links to a spatial grid, calculating grid-cell totals and the relative change compared to the reference scenario. Visualized in QGIS.

- **`Scaper output checks.sql`** – SQL queries for checking consistency in Scaper output data, including vehicle counts, traffic flow by link and hour, level of service and travel distances. Identifies anomalies such as unrealistic speeds or traffic accumulation. Provides the basis for the visualizations in `Scaper output diagnostics.xlsx`.






