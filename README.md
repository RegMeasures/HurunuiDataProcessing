# HurunuiDataProcessing
Matlab processing scripts to analyse monitoring data from the Hurunui Hapua. The most important analysis scripts are:

Script                                  |Purpose
----------------------------------------|------------------------------------------------------
[OrganiseImages](OrganiseImages.m)      |For adding/orgnasing photos into logical sub-directory structure for storage/management. This script is run to process downloaded images after bringing them back to the office.
[ImageAnalysis](ImageAnalysis.m)|Main image processing workflow
[TimeseriesAnalysis](TimeseriesAnalysis)|Main timeseries processing workflow

These functions rely on functions and static data/inputs contained with the [functions/](functions) and [inputs/](inputs) folders. The [test_scripts/](test_scripts) folder contains scripts used to test/develop other functions.
