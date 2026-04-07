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

## Configuring EWAS catalog website

Configure the EWAS catalog by creating
`config.env` and `settings.env` files based on the templates provided.

* `OUT_DIR` will contain all files needed to support a running version
  of the EWAS catalog including apptainer container files implementing 
  the database, website and web server. 
* `REPO_DIR` is the path to this repository on the file system.
* `DATA_DIR` is the folder containing annotation files for CpG sites and genes
  and a sub-folder `studies` containing the EWAS meta-data and summary statistics
* `SETTINGS` provides the location of the `settings.env` file containing 
  the database name, user names and passwords, website and webserver hosts and ports. 

Notice that, by specifying different versions of `config.env` and `settings.env`, 
it is possible to have multiple versions of the EWAS catalog installed, 
e.g. a production version and a smaller test version.

## Building the EWAS catalog

Building the EWAS catalog typically takes some time
because it involves creating three apptainer containers
(to implement the database, website and web server), a database 
and adding any EWAS data in `DATA_DIR/studies/` to the database.

This can be done with the following command:

```
bash ewascatalog/scripts/build.sh config.env
```

## Running the EWAS catalog

Once built, the EWAS catalog website can be started.
```
bash ewascatalog/scripts/start.sh config.env
```

Locally, the website will be available at 
`WEBSITE_HOST:WEBSITE_PORT`
depending on `settings.env` (default 127.0.0.1:9980).

The EWAS catalog can be taken offline or stopped. 
```
bash ewascatalog/scripts/stop.sh config.env
```

## Adding new data

New data can be provided as a folder in `DATA_DIR/studies` containing:

* A `studies.csv` file with one row per EWAS

  > These should at least have the following columns:
  > "first author", "cohorts or consortia used", "pubmed id", "date",
  > "trait", "trait units", "was dna methylation the outcome or exposure
  > for your ewas model?", "dna methylation units", "analysis",
  > "covariates (select all that apply. for meta-analysis entries select
  > the covariates commonly used across studies.)", "results file name",
  > "source", "other covariates", "technology used to measure
  > methylation", "tissue", "further details", "n", "n cohorts", "age
  > group (most common in ewas)", "sex", 
  > "ancestry (select all that apply)". 
  > **We typically create them by completing a jotform.**

* For each EWAS, a csv with summary statistics with a filename 
  that matches the "results file name" column in `studies.csv`. 
  
  > These should at least have the following columns: 
  > "cpg", "beta", "se", "p" and "details". 

For data in a folder `DATA_DIR/studies/FOLDERNAME`, 
we first run formatting checks and prepare it to be added 
to the datbase as following:

```
bash ewascatalog/scripts/prep.sh config.env FOLDERNAME
```

If all format checks are passed, 
this will create two files, `study.txt` and `results.txt`
in that folder (i.e. `DATA_DIR/studies/FOLDERNAME`). 

The 'efo' column in `studies.txt` will default to "EFO_0000001". 
These should be replaced with more specific values manually
by consulting https://www.ebi.ac.uk/ols4/ontologies/efo. 

> **Alternatively**, for publications with many EWAS, 
> it may be more convenient to create the `studies.txt` 
> and `results.txt` files directly. 
> Both are tab-delimited files. `studies.txt` has the following 
> columns: "author","consortium","pmid","date","trait","efo",
> "analysis","source","outcome","exposure","covariates",
> "outcome_units","exposure_units","methylation_array","tissue","further_details","n","n_cohorts","age","sex",
> "ethnicity".
> `results.txt` has the following columns: 
> "cpg", "beta", "se", "p" and "details". 

The new data
can be added to the database 
by running the following command:

```
bash ewascatalog/scripts/update.sh config.env
```

## Removing data

Study data corresponding to any specific folder in `DATA_DIR/studies`
(e.g. `DATA_DIR/studies/FOLDERNAME`)
can be removed from the database by running the following command:

```
bash ewascatalog/scripts/remove.sh config.env FOLDERNAME
```


