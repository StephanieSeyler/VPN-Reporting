# SonicWall Reporting
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://choosealicense.com/licenses/mit/)
[![Mainteneance](https://img.shields.io/maintenance/yes/2021?style=plastic)]()
[![Powershell](https://img.shields.io/badge/Powershell-v%205.1-orange)](https://www.microsoft.com/en-us/download/details.aspx?id=54616)

Report to leverage the SonicOS API to build a report for VPN licensing
Leverages the SonicWall API using Curl to make API Calls
Reporting and Charts are built in Powershell.

## Installation

1. Download the Repository 
2. Install Dashimo module & Dashimo
```Powershell
Install-Module -Name PSWriteHTML -AllowClobber -Force
Install-Module -Name Dashimo -AllowClobber -Force
```

## Features
Build a single pane of glass dashboard to view licensing and other information about your Sonicwall VPN appliances
Line Chart of past day of activity
Record of historical usage data of the VPN appliances

## Usage
Code is ran from ps1 file in \scripts\ folder with Configuration of the API targets and other data is stored in \scripts\config.json. TheAmount of VPN appliances monitored can be scaled up and down based on entries in config file.

## RoadMap
Implement grouping of data on line Chart - Planned


## Releases
v1.0.0 Rebuilt code base to run everything through a configuration file

## Authors
Stephanie Seyler  

## Project Status
in progress

## license 
[MIT](https://choosealicense.com/licenses/mit/)
