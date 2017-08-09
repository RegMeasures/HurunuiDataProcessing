# HurunuiDataProcessing
Matlab processing scripts to analyse monitoring data from the Hurunui Hapua.  

## Background
Hapua are non-estuarine river mouth lagoons which form at the mouths of steep gravel bed rivers on high wave energy micro-meso tidal coastlines. Hapua have elongated shore-parallel lagoons seperated from the sea by a mixed sand and gravel beach barrier. A highly dynamic outlet channel flows through the beach barrier to the sea. Their outlet channels change rapidly in response to river flows, waves and, to a lesser extent, tides. Outlet processes include migration along the barrier, changes in length and orientation, closure, and barrier breach to form a new oulet. As part of a project to better understand hapua responses to changing drivers (e.g. changed river flow regimes due to water extraction) intensive monitoring of the Hurunui Hapua is being conducted. Analysis of this data is required in order to understand the links between observed drivers and lagoon responses, and to generate a robust calibration/validation data set for planned modelling of hapua processes.

The Hurunui River drains a catchment of 2669 km<sup>2</sup>, from the main divide of the Southern Alps to the East Coast of the South Island, New Zealand. Where it emerges onto the coastline there is a 1.5 km long shore parallel lagoon (hapua).

## Monitoring data
Data used in this analysis of the Hurunui Hapua includes:
- **Timelapse cameras:** Two timelapse cameras are mounted on an 8 m utility pole in the centre of the lagoon backshore. One camera points towards the north-east end of the lagoon and one towards the south-west. The cameras record colour images every 15 minutes during daylight hours.
- **Water level recorder:** A telemetered lagoon water level recorder is sited in the center of the lagoon directly below the cameras.
- **River flow gauge:** [Environment Canterbury](https://www.ecan.govt.nz/) maintain a flow recorder 20km upstream from the coast at the SH1 bridge over the the Hurunui River ([Station 65101](https://sims.niwa.co.nz/sims/station.do?locationId=1029)). The data is available for download at https://www.ecan.govt.nz/data/riverflow/sitedetails/65101.
- **Wave buoy:** A wave buoy 100 kms to the south of the hapua monitors the deep water wave climate. It is maintained by [NIWA](https://www.niwa.co.nz) and partially funded by [Environment Canterbury](https://www.ecan.govt.nz/). The real timwe data is visible at https://www.ecan.govt.nz/data/current-wave-data/.
- **Sea level:** Sea level monitoring is conducted by [NIWA](https://www.niwa.co.nz) at Sumner ([Station 66699](https://sims.niwa.co.nz/sims/station.do?locationId=1127)). Real time data is visible at https://www.niwa.co.nz/our-science/coasts/tools-and-resources/sea-levels/sumner-head.

## Matlab analysis (this repository)
The most important analysis scripts are:

Script                                  |Purpose
----------------------------------------|------------------------------------------------------
[OrganiseImages](OrganiseImages.m)      |For adding/organising photos into a logical sub-directory structure for storage/management. This script is run to process downloaded images after bringing them back to the office.
[ImageAnalysis](ImageAnalysis.m)        |Main image processing workflow
[TimeseriesAnalysis](TimeseriesAnalysis)|Main timeseries processing workflow

These scripts rely on functions and static data/inputs contained with the [functions/](functions) and [inputs/](inputs) folders. The [test_scripts/](test_scripts) folder contains scripts used to test/develop other functions.

## Acknowledgements
This code has been developed as part of Richard Measures' part time PhD research in the [Hydrological and Ecological Engineering research group at the University of Canterbury Department of Civil and Natural Resources Engineering](http://www.civil.canterbury.ac.nz/hydroeco/abouthydro.shtml). 
Richard is a Hydrodynamics Scientist in the Sediment Processes team at the [National Institute of Water and Atmospheric Research](https://www.niwa.co.nz) based in Christchurch New Zealand. NIWA has funded this research through the [Sustainable water Allocation Programme](https://www.niwa.co.nz/freshwater-and-estuaries/programme-overview/sustainable-water-allocation).
