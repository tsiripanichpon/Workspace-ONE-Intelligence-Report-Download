#!/usr/bin/env python
# coding: utf-8

import requests
import json
import csv
import argparse
from datetime import datetime
import time

parser = argparse.ArgumentParser()
parser.add_argument("-Region", help="region name", required=True)
parser.add_argument("-ReportId", help="report id", required=True)
parser.add_argument("-ClientId", help="client id", required=True)
parser.add_argument("-ClientSecret", help="client secret", required=True)
parser.add_argument("-OutFile", help="output file name", required=True)
args = parser.parse_args()

region = args.Region
report_id = args.ReportId
client_id = args.ClientId
client_secret = args.ClientSecret
out_file = args.OutFile


def get_access_token(url, client_id, client_secret):
    try:
        data = {'grant_type': 'client_credentials', 'client_id': client_id, 'client_secret': client_secret}
        response = requests.post(url, data=data)
        response.raise_for_status()
        return response.json()['access_token']
    except requests.exceptions.RequestException as e:
        print("Error getting access token:", e)
        return None

def run_report(report_id, url, access_token):
    try:
        url_run = url + report_id + "/run"
        headers = {'Authorization': 'Bearer ' + access_token, 'content-type': 'application/json'}
        response = requests.post(url_run, headers=headers)
        response.raise_for_status()
        print("Running report...")
        time.sleep(30) # add delays to prevent race condition where reports are not yet generated but report list may be retrieved
    except requests.exceptions.RequestException as e:
        print("Error running report:", e)

def get_report_list(report_id, url, access_token):
    try:
        url_report_list = url + report_id + "/downloads/search"
        headers = {'Authorization': 'Bearer ' + access_token, 'content-type': 'application/json'}
        data = {'offset': '', 'page_size': 200}
        response = requests.post(url_report_list, headers=headers, data=json.dumps(data))
        response.raise_for_status()
        report_list_json = response.json()['data']['results']
        report_list_json.sort(key=lambda x: x['start_time'], reverse=True)
        print("Getting report list...")
        return report_list_json
    except requests.exceptions.RequestException as e:
        print("Error getting report list:", e)
        return None

def download_report(scheduled_id, url, access_token):
    try:
        url_download = url + 'tracking/' + scheduled_id + "/download"
        headers = {'Authorization': 'Bearer ' + access_token, 'content-type': 'application/json'}
        response = requests.get(url_download, headers=headers)
        response.raise_for_status()
        print("Downloading report...")
        return response.content
    except requests.exceptions.RequestException as e:
        print("Error downloading report:", e)
        return None

def save_report(out_file_name, downloaded_report):
    try:
        with open(out_file_name, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(csv.reader(downloaded_report.decode('utf-8').splitlines()))
        print("Saving report...")
    except IOError as e:
        print("Error saving report:", e)

def main(region, report_id, client_id, client_secret, out_file):
    base_api_url = "https://api." + region + ".data.vmwservices.com/v1/reports/"
    base_auth_url = "https://auth." + region + ".data.vmwservices.com/oauth/token"
    access_token = get_access_token(base_auth_url, client_id, client_secret) # generate access token
    run_report(report_id, base_api_url, access_token) # run report
    report_list = get_report_list(report_id, base_api_url, access_token) # get the list of all available reports for downloads
    scheduled_id = report_list[0]['id'] # get the latest available report
    downloaded_report = download_report(scheduled_id, base_api_url, access_token) # download report
    save_report(out_file, downloaded_report) # save report
    
if __name__ == "__main__":
    main(region, report_id, client_id, client_secret, out_file)

