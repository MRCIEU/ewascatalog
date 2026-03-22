
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
However, bare in mind that the website will be unavailable 
during this time.
```
bash scripts/update.sh config.env
```
