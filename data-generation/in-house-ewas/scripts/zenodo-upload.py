# script to upload a file to zenodo sandbox via api
# seperate sandbox- and real-zenodo accounts and ACCESS_TOKENs each need to be created

# to adapt this script to real-zenodo (from sandbox implementation):
    # update urls to zenodo.org from sandbox.zenodo.org
    # update SANDBOX_TOKEN to a ACCESS_TOKEN from real-zenodo

import sys, json, requests, pathlib, re
import pandas as pd

file_dir="results/geo/derived"
file_dir = sys.argv[1]
access_token = sys.argv[2]

print('Starting Zenodo upload process')

# specify ACCESS_TOKEN
  # this needs to be generated for each sanbox/real account
ACCESS_TOKEN = access_token

# create empty upload
headers = {"Content-Type": "application/json"}
r = requests.post('https://zenodo.org/api/deposit/depositions', params={'access_token': ACCESS_TOKEN}, json={}, headers=headers)
# r = requests.post('https://sandbox.zenodo.org/api/deposit/depositions', params={'access_token': ACCESS_TOKEN}, json={}, headers=headers)

r.status_code
r.json()

# Get the deposition id from the previous response
# Upload the file to be deposited to Zenodo
deposition_id = r.json()['id']
bucket_url = r.json()["links"]["bucket"]
# New API
filename = "full_stats.tar.gz"
path = file_dir+"/%s" % filename

# The target URL is a combination of the bucket link with the desired filename
# seperated by a slash.
with open(path, "rb") as fp:
    r = requests.put(
        "%s/%s" % (bucket_url, filename),
        data=fp,
        params={'access_token': ACCESS_TOKEN},
    )
r.json()

filename = "studies-full.csv"
path = file_dir+"/%s" % filename

with open(path, "rb") as fp:
    r = requests.put(
        "%s/%s" % (bucket_url, filename),
        data=fp,
        params={'access_token': ACCESS_TOKEN},
    )
r.json()

## SHOULD REALLY CHANGE THIS SO IT CAN BE READ IN!
# desc='Full summary statistics from 387 epigenome-wide association studies (EWAS) conducted by The EWAS Catalog team (www.ewascatalog.org). Meta-data is found in the "studies-full.csv" file and the results are in "full-stats.tar.gz". Unzipping the "full-stats.tar.gz" file will reveal a folder containing 387 csv files, each with the full summary statistics from one EWAS. The results can be linked to the meta-data using the "Results_file" column in "studies-full.csv". These analyses were conducted using data from the Accessible Resource for Integrated Epigenomics Studies (ARIES) subset of the Avon Longitudinal Study of Parents and Children (ALSPAC) cohort. For more information on the EWAS, please consult our paper: Battram, Thomas, et al. “The EWAS Catalog: A Database of Epigenome-wide Association Studies.” OSF Preprints, 4 Feb. 2021. https://doi.org/10.31219/osf.io/837wn. Please cite the paper if you use the dataset.'
desc='Full summary statistics from 41 epigenome-wide association studies (EWAS) conducted by The EWAS Catalog team (www.ewascatalog.org). Meta-data is found in the "studies-full.csv" file and the results are in "full_stats.tar.gz". Unzipping the "full_stats.tar.gz" file will reveal a folder containing 41 csv files, each with the full summary statistics from one EWAS. The results can be linked to the meta-data using the "Results_file" column in "studies-full.csv". These analyses were conducted using data extracted from the Gene Expression Omnibus (GEO). These data were extracted using the geograbi R package. For more information on the EWAS, please consult our paper: Battram, Thomas, et al. “The EWAS Catalog: A Database of Epigenome-wide Association Studies.” OSF Preprints, 4 Feb. 2021. https://doi.org/10.31219/osf.io/837wn. Please cite the paper if you use this dataset.'

data = {'metadata': 
					{'title': 'Full summary statistics from 41 EWAS conducted for the EWAS Catalog', 
					 'upload_type': 'dataset', 
					 'description': desc,
					 'creators': [{'name': 'EWAS Catalog team', 'affiliation': 'MRC Integrative Epidemiology Unit, University of Bristol'}],
					 'keywords': ['EWAS', 'Epigenetics'], 
					 'communities': [{'identifier': 'ewas-catalog'}]}}

r = requests.put('https://zenodo.org/api/deposit/depositions/%s' % deposition_id, params={'access_token': ACCESS_TOKEN}, data=json.dumps(data), headers=headers)
# r = requests.put('https://sandbox.zenodo.org/api/deposit/depositions/%s' % deposition_id, params={'access_token': ACCESS_TOKEN}, data=json.dumps(data), headers=headers)

r.status_code
r.json()

# publish 
r = requests.post('https://zenodo.org/api/deposit/depositions/%s/actions/publish' % deposition_id, params={'access_token': ACCESS_TOKEN} )
# r = requests.post('https://sandbox.zenodo.org/api/deposit/depositions/%s/actions/publish' % deposition_id, params={'access_token': ACCESS_TOKEN} )

status_code = r.status_code
if status_code != 202:
	raise ValueError("Status code was" + str(status_code) + " and it should be 202. Check zenodo")
else:
	print("Status code is 202. Happy days!")
# should be: 202
