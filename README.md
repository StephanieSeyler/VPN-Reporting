# SonicWall Reporting
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://choosealicense.com/licenses/mit/)
[![version](https://img.shields.io/badge/Production%20Version-0.4.1-brightgreen)]()
[![Mainteneance](https://img.shields.io/maintenance/yes/2020?style=plastic)]()
[![Powershell](https://img.shields.io/badge/Powershell-v%205.1-orange)](https://www.microsoft.com/en-us/download/details.aspx?id=54616)
[![Social](https://img.shields.io/twitter/follow/StephSeyler?style=social)](https://img.shields.io/twitter/follow/StephSeyler?style=social)

Reporting on the Current Usage statistics of our SonicWall Appliances Globally.
Leverages the SonicWall API using Curl to make API Calls
Reporting and Charts are built in Powershell.

## Installation

1. Download the Repository from the RES Infrastructure Project page that will contain all scripts and supporting files.
2. Install Dashimo module & Dashimo
```Powershell
Install-Module -Name PSWriteHTML -AllowClobber -Force
Install-Module -Name Dashimo -AllowClobber -Force
```

## Features

## Usage
Run the Ps1 script to generate the report, Chart will display once a full day of data points has been collected.

## RoadMap

## Releases
v0.1.0 Released 2020-03-18 - Initital Release 

v0.2.0 Released 2020-03-19 - Logging, Error Handling, Better documentation

v0.3.0 Released 2020-03-20 - Included Curl commands in Script, improved logging and HTML

v0.4.0 Released 2020-03-25 - Obfuscated API credentials and removed unused functions, implemented relative pathing to script call location

v0.4.1 Released 2020-06-05 - Updated to add new Appliance to data set, Added Totals for EMEA 

## Support

tickets@res-group.com

## Authors
Stephanie Seyler 

## Project Status
Completed

## license 
[MIT](https://choosealicense.com/licenses/mit/)