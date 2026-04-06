
# EWAS catalog (new version Mar 22, 2026)

> Battram, Thomas, Paul Yousefi, Gemma Crawford, Claire Prince, Mahsa
> S. Babei, Gemma Sharp, Charlie Hatcher, et al. 2021.
> ["The EWAS Catalog: A Database of Epigenome-wide Association Studies."](https://osf.io/837wn)
> OSF Preprints. February 4. doi:10.31219/osf.io/837wn.

## Overview

Instructions, code and data for installing the EWAS Catalog.

This repository contains all code related to the EWAS Catalog.

Files are divided into the following directories:

- `data-generation`: information and code describing the origin of some EWAS summary statistics in the database
  - `in-house-ewas`: Scripts and instructions for EWAS performed by us
  - `published-ewas`: Information about how published studies are chosen for inclusion
- `website`: website python code (Django)
- `database`: scripts for creating and populating the database from data found in the `DATA_DIR` 
- `webserver`: configuration files for the webserver
- `logo`: logo graphics files

## Building and running the EWAS catalog website

Before running the EWAS catalog website, it must be 
configured and built. 

Configure the website by creating
`config.env` and `settings.env` files from the templates provided.

Building the website involves populating the database 
from summary statistics in `DATA_DIR`
and setting up the website files.
```
bash scripts/build.sh config.env
```

> Everything is put in `OUT_DIR`
> specified in `config.env`, e.g. `live`. 
> As a result, it is possible to have multiple versions of the 
> catalog, just run `build.sh` with a different output directory name.

Once built, the EWAS catalog website can be started.
```
bash scripts/start.sh config.env
```

Locally, the website will be available at 
`WEBSITE_HOST:WEBSITE_PORT`
depending on `settings.env` (default 127.0.0.1:8080).


Once started, the EWAS catalog can be taken offline or stopped. 
```
bash scripts/stop.sh config.env
```

Finally, once built, 
the EWAS catalog can be updated, 
e.g. to add new data. 
However, bear in mind that the website will be unavailable 
during this time.

First, download the study metadata uploaded to jotform 
(as `studies.csv` with one row per EWAS)
and retrieve the summary statistics uploaded to dropbox 
(one csv file per EWAS).
With both of these in the same folder: 
```
bash scripts/prep.sh config.env path/to/folder
```

This will create 'study.txt' and 'results.txt' files
in the same folder. 

Copy this folder to `data/studies/`
and add to the database. 
```
bash scripts/update.sh config.env
```

If an error is identified in the update, 
it can be reversed:

```
bash scripts/remove.sh config.env path/to/folder
```

## TODO 

There is something not quite right with how 
the database and website containers communicate.  
It would be better not to have to create `/tmp/*.sock`
files is `/tmp` is a public directory. 
Probably better to create socket files 
in the shared RAM-disk (`/dev/shm`). 
Also looks like the python running the website 
is actually using TCP?
-- see minimal-webapp for an example
