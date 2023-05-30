# This script gets the latest data from an existing Workspace ONE Intelligence report and download the report as a CSV.

# Now you can use the script by calling it and passing the required parameters like this:
# .\Get-IntelligenceReport.ps1 -Region "sandbox" -ReportId "XXXXXXX" -ClientId "XXXXXXX" -ClientSecret "XXXXXX" -OutFile "XXXXXXXXX_$(Get-Date -Format "yyyyMMddHHmmss").csv"



param (
    [string]$Region,
    [string]$ReportId,
    [string]$ClientId,
    [string]$ClientSecret,
    [string]$OutFile
)


# Obtain a bearer token from Workspace ONE Intelligence Auth service using client ID and client secret. 
function Get-AccessToken($url, $client_id, $client_secret) {
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Body @{grant_type="client_credentials"; client_id=$client_id; client_secret=$client_secret} -ErrorAction Stop
        return $response.access_token
    } catch {
        Write-Error "Error getting access token: $($_.Exception.Message)"
        return $null
    }
}

# Taking the bearer access token, generate a new report entry for a specified report based on a report ID. A specific report ID can be found in the URL of Workspace ONE Intelligence report. The report ID follows the UUID format (xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx)
# 30 seconds delayed are added. For larger report, update this value to allow for additional time for report generation.
function Run-Report($report_id, $url, $access_token) {
    try {
        $url_run = $url + $report_id + "/run"
        $headers = @{
            'Authorization' = "Bearer " + $access_token
            'content-type' = "application/json"
        }
        Invoke-RestMethod -Uri $url_run -Method Post -Headers $headers -ErrorAction Stop
	    Write-Progress -Activity "Running report" -Status "Report is being generated" -PercentComplete 25
	    Start-Sleep -Seconds 30 # add delays to prevent race condition where reports are not yet generated but report list may be retrieved
    } catch {
        Write-Error "Error running report: $($_.Exception.Message)"
    }
}

# Taking the bearer access token, get the list of all available report data from based on a report ID. A specific report ID can be found in the URL of Workspace ONE Intelligence report. The report ID follows the UUID format (xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx)
# The output is a report list, in JSON format, and contains the list scheduled IDs which are different report versions based on when the reports were run/generated. The scheduled ID will also follow the UUID format.
function Get-Report-List($report_id, $url, $access_token) {
    try {
        $url_report_list = $url + $report_id + "/downloads/search"
        $headers = @{
            'Authorization' = "Bearer " + $access_token
            'content-type' = "application/json"
        }
        $body = '{"offset":"","page_size":200}'
        $report_list = Invoke-RestMethod -Uri $url_report_list -Method Post -Headers $headers -Body $body -ErrorAction Stop
        $report_list_json = $report_list.data.results
        $report_list_json | Sort-Object -Property start_time -Descending
	    Write-Progress -Activity "Getting report list" -Status "Report list retrieved" -PercentComplete 50
        return $report_list_json
    } catch {
        Write-Error "Error getting report list: $($_.Exception.Message)"
        return $null
    }
}

# Taking the bearer access token, download report data based on scheduled ID. The output is in JSON format.
function Download-Report($scheduled_id, $url, $access_token) {
    try {
        $url_download = $url + 'tracking/' + $scheduled_id + "/download"
        $headers = @{
            'Authorization' = "Bearer " + $access_token
            'content-type' = "application/json"
        }
        $downloaded_report = Invoke-RestMethod -Uri $url_download -Method Get -Headers $headers -ErrorAction Stop
	    Write-Progress -Activity "Downloading report" -Status "Report downloaded" -PercentComplete 75
        return $downloaded_report
    } catch {
        Write-Error "Error downloading report: $($_.Exception.Message)"
        return $null
    }
}

# Taking the JSON result, convert to CSV and save it based on the input file name.
function Save-Report($out_file_name, $downloaded_report) {
    try {
        $downloaded_report | ConvertFrom-Csv | Export-Csv -Path $out_file_name -NoTypeInformation
	    Write-Progress -Activity "Saving report" -Status "Report saved" -PercentComplete 100
    } catch {
        Write-Error "Error saving report: $($_.Exception.Message)"
    }
}

function Main() {
    $BaseApiUrl = "https://api." + $Region + ".data.vmwservices.com/v1/reports/"
    $BaseAuthUrl = "https://auth." + $Region + ".data.vmwservices.com/oauth/token"
    $access_token = Get-AccessToken $BaseAuthUrl $ClientId $ClientSecret # generate access token
    Run-Report $ReportId $BaseApiUrl $access_token # run report
    $report_list = Get-Report-List $ReportId $BaseApiUrl $access_token # get the list of all available reports for downloads
    $scheduled_id = $report_list[0].id # get the latest available report
    $downloaded_report = Download-Report $scheduled_id $BaseApiUrl $access_token # download report
    Save-Report $OutFile $downloaded_report # save report
}

Main

