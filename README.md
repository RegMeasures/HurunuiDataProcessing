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
- **Wave buoy:** A wave buoy 100 kms to the south of the hapua monitors the deep water wave climate. It is maintained by [NIWA](https://www.niwa.co.nz) and partially funded by [Environment Canterbury](https://www.ecan.govt.nz/). Real time data is visible at https://www.ecan.govt.nz/data/current-wave-data/.
- **Sea level:** Sea level monitoring is conducted by [NIWA](https://www.niwa.co.nz) at Sumner ([Station 66699](https://sims.niwa.co.nz/sims/station.do?locationId=1127)). Real time data is visible at https://www.niwa.co.nz/our-science/coasts/tools-and-resources/sea-levels/sumner-head.

## Matlab analysis (this repository)
The most important analysis scripts are:

Script                                  |Purpose
----------------------------------------|------------------------------------------------------
[OrganiseImages](OrganiseImages.m)      |For adding/organising photos into a logical sub-directory structure for storage/management. This script is run to process downloaded images after bringing them back to the office.
[ImageAnalysis](ImageAnalysis.m)        |Main image processing workflow
[TimeseriesAnalysis](TimeseriesAnalysis.m)|Main timeseries processing workflow
[MapOutletChannel](MapOutletChannel.m)  |Semi-manual identification of outlet channel position
[OutputPlots](OutputPlots.m)            |Production of results figures for publication etc.

These scripts rely on functions and static data/inputs contained with the [functions/](functions) and [inputs/](inputs) folders. The [test_scripts/](test_scripts) folder contains scripts used to test/develop other functions.

## External code
### export-fig
HurunuiDataProcessing uses [export_fig](https://github.com/altmany/export_fig) for exporting publication quality figures. Export_fig is included as a submodule in the HurunuiDataAnalysis respoitory (in [functions/externals](functions/externals)). To export PDF format figures export_fig requires Ghostscript be installed, a free download available from http://www.ghostscript.com/. To export EPS format figures export_fig requires pdftops.exe, part of the Xpdf tools available freely from http://www.xpdfreader.com.

### Gibbs SeaWater (GSW) Oceanographic Toolbox of TEOS-10
To convert from conductivity to salinity HurunuiDataProcessing uses the [Gibbs SeaWater (GSW) Oceanographic Toolbox of TEOS-10](http://www.teos-10.org/software.htm). The matlab toolbox of these functions, GSW-Matlab, is avalable on GitHub ([https://github.com/TEOS-10/GSW-Matlab](https://github.com/TEOS-10/GSW-Matlab)) and is included as a submodule in the HurunuiDataAnalysis respoitory (in [functions/externals](functions/externals)).

### t-tide
t-tide (Pawlowicz et al. 2002) is used for tidal analysis. This is a free set of tools available for download ([https://www.eoas.ubc.ca/~rich/#T_Tide](https://www.eoas.ubc.ca/~rich/#T_Tide)) and a copy is included in the HururnuiDataAnalysis repository ([functions/t_tide_v1.3beta](functions/t_tide_v1.3beta))

### OpenEarthTools
OpenEarthTools contains many useful matlab functions. More information about the OpenEarth initiative is available at [https://publicwiki.deltares.nl/display/OET](https://publicwiki.deltares.nl/display/OET). Only a small sub-set of the many available matlab functions have been used in HurunuiDataAnalysis. These have been copied into the repository at [functions/OpenEarthTools](functions/OpenEarthTools).

### ts_package
The ts_package functions for producing stacked timeseries plots are available on Matlab File Exchange: [https://mathworks.com/matlabcentral/fileexchange/60990-stacked-time-series-plots](https://mathworks.com/matlabcentral/fileexchange/60990-stacked-time-series-plots). These functions have been copied into the HurunuiDataAnalaysis repository ([functions/ts_package](functions/ts_package)) and have been modified to allow customisation to plot formats.

### wind_rose
The wind_rose function for producing wind rose plots is available on Matlab File Exchange: [http://au.mathworks.com/matlabcentral/fileexchange/17748-wind-rose](http://mathworks.com/matlabcentral/fileexchange/17748-wind-rose). The function has been copied into the HurunuiDataAnalysis repository ([functions/wind_rose](functions/wind_rose)) and slightly modified.

## Acknowledgements
[NIWA](https://www.niwa.co.nz) has funded this research through the [Sustainable water Allocation Programme](https://www.niwa.co.nz/freshwater-and-estuaries/programme-overview/sustainable-water-allocation).

This code has been developed as part of Richard Measures' part time PhD research in the [Hydrological and Ecological Engineering research group at the University of Canterbury Department of Civil and Natural Resources Engineering](http://www.civil.canterbury.ac.nz/hydroeco/abouthydro.shtml). Richard's PhD supervisors are [Tom Cochrane](http://www.canterbury.ac.nz/engineering/schools/cnre/contact-us/academic-staff/tom-cochrane.html), [Deirdre Hart](https://www.canterbury.ac.nz/science/contact-us/people/deirdre-hart.html) and [Murray Hicks](https://www.niwa.co.nz/people/murray-hicks).

## References
Pawlowicz, R., Beardsley, B., Lentz, S., 2002. Classical tidal harmonic analysis including error estimates in MATLAB using T_TIDE. Comput. Geosci. 28, 929–937. doi:10.1016/S0098-3004(02)00013-4. http://www.sciencedirect.com/science/article/pii/S0098300402000134  

