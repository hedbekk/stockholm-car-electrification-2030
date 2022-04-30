# KTH Thesis Project
<dl>
  <dt>Thesis Title:</dt>
    <dd>The Potential of Electrification in reducing Emissions from Passenger Cars in Stockholm County by 2030: A Modeling Study of the Potential of Plug-In Hybrids and All-Electric Cars in reducing Greenhouse Gas Emissions and Air Pollution</dd>
</dl>
To read the report and abstract, go to: https://www.diva-portal.org/smash/record.jsf?pid=diva2%3A1578459&dswid=7135

## Main Content of Repository:

<dl>
  <dt>SQL scripts (folder)</dt>
    <dd>
        Contains three sql-scripts with about 2000 lines of code in total:
      <ul>
        <li>Data quality checks.sql – Code to assess the quality of the output data from the Scaper transportation   model.</li>
        <li>Main.sql – Used for calculating emissions, which was done vehicle-by-vehicle without pre-aggregating traffics flows based on the output data from the Scaper transportation model. The main part of entire thesis.</li>
        <li>PM visulizationz.sql – Code for visualizing the geographical distribution of PM emissions.</li>
      </ul>
    </dd>
  <dt>Bilscenarier.xlsm*
    <dd>Contains all calculations used to create each of the five scenarios for municipality-level car fleet compositon in 2030 (i.e. the number of all-electric, plug-in hybrid, gasoline and diesel vehicles in each of the 26 municipalities of Stockholm County in 2030). In short, these scenarios have been made using historic car sales and car ownership data for the period 2010-2019.</dd>
  <dt>Cold start calculations.xlsm</dt>
    <dd>Calculations for converting 1476 cold start emission factors from g/start to continuous (exponentially decreasing) functions of the driving distance. This automated using VBA, using the Excel Solver and the method of least squares.</dd>
  <dt>Quality check of scenario data.xlsx</dt>
    <dd>Visualizations of the querries run from Data quality checks.sql</dd>
  <dt>Transports.gqz</dt>
    <dd>QGIS project for visualizing the geographical distribution of emissions.</dd>
</dl>

<br>
<br>
*Note: With what I have since learned, if I would redo the scenarios I would create a data model in Power Pivot instead of having 20 tabs for car sales and car ownership in a single workbook. I would also make use of tables and use more VBA.
