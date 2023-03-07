## Overview

Author: Targoon Siripanichpong

Email: tsiripanichpon@vmware.com

Date Created: 3/7/2023

## Purpose

Leveraging Workspace ONE Intelligence API to automate the process of getting the latest data from Workspace ONE Intelligence, downloading, and saving the report as CSV.

## Requirements

1. Generate Workspace ONE Intelligence Service Account (getting client ID and client sercret)
2. Create a report and share it with the Service Account
3. Obtain the report ID

## How to execute the script

Execute the script using the following parameters:

- Region - Workspace ONE Intelligence API region. More information here:  https://docs.vmware.com/en/VMware-Workspace-ONE/services/intelligence-documentation/GUID-04_intel_reqs.html 
- ReportId - Existing Workspace ONE Intelligence report ID 
- ClientId - Client ID of the service account 
- ClientSecret - Client Secret of the service account 
- OutFile - Targeted output file path & file name 

Example (Python): python3 IntelligenceReportDownload.py -Region "sandbox" -ReportId "XXX" -ClientId "XXX" -ClientSecret "XXX" -OutFile "device_report.csv"

Example (Powershell): .\Intelligence_report_download_ps.ps1 -Region "sandbox" -ReportId "XXX" -ClientId "XXX" -ClientSecret "XXX" -OutFile "device_$(Get-Date -Format "yyyyMMddHHmmss").csv"

## Change Log

3/7/2023 - Initial upload
