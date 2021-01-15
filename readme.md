# EWAS Catalog website

Instructions, code and data for installing the EWAS Catalog.

This repository contains all code related to the EWAS Catalog.
The catalog website and database is installed and updated by [catalog](catalog)
script commands in a docker container. 

Files are divided into the following directories:

- `published-ewas`: collected published EWAS summary statistics
- `website`: website python code (Django)
- `database`: scripts for creating and populating the database from data found in the `FILES_DIR` (see below)
- `docker`: initialization files and scripts for installing the website and database within a docker container
- `webserver`: configuration files for the webserver
- `r-package`: R package for accessing the database
- `logo`: logo graphics files
- `in-house-ewas`: Scripts and instructions for EWAS performed by us

## Environment

Variables for the accessing the database can be found in `settings.env`.
A copy is located here:
```
/projects/MRC-IEU/research/projects/ieu1/wp2/004/working/scripts/ewascatalog2/settings.env
```

## Running docker commands

The system will run within a Docker container. 

For a user to run docker commands,
they will need to belong to the 'docker'
linux permissions group.
```
sudo usermod -a -G docker [USER]
```
For this change to take effect, the user
will need to logout and then login.

## Building the EWAS Catalog

The entire pipeline is defined in the [catalog](catalog) script,
and the catalog can be built with the following command:

```
bash catalog all
```

*Before* running it, however, you will need to assign values to
variables `FILES_DIR`, `WEBSITE_DIR` and `SETTINGS` in [catalog](catalog).

`FILES_DIR` should provide the path to the directory
containing catalog data files.
A copy of this directory is here:
```
/projects/MRC-IEU/research/projects/ieu1/wp2/004/working/data/data-files-for-ewascatalog2
```

`WEBSITE_DIR` should provide the path to the base directory
where the website files will be located on the host machine.

`SETTINGS` should provide the path to the `settings.env` file
described earlier.

That single step is actually composed of a sequence of several sub-steps:

1. `bash catalog build`: copy docker files to the website and build the docker container
2. `bash catalog start`: start the docker container running
3. `bash catalog create-database`: create and populate the database with EWAS summary statistics

## Navigating to the website

The website can be found at `localhost:8080`
or `[host IP address]:8080` or `[host name]:8080`.

## Making changes

Changes to the repository can be reflected in the running EWAS catalog as follows:

- `website/`: Run `bash catalog update-website` and reload the website in the browser.
  This will copy the files to the running website
  and restart the 'web' docker service (defined [docker/docker-compose.yml](docker/docker-compose.yml)).
- `database/`: This is more complicated. Details can be found [database/readme.md](database/readme.md).
- `docker/`: Probably need to stop and start the whole thing (i.e. `bash catalog stop` and then `bash catalog start`).
- `webserver/`: Run `bash catalog update-webserver` and reload the website in the browser.
  This will copy the files to the running website
  and restart the 'nginx' docker service (defined [docker/docker-compose.yml](docker/docker-compose.yml)).

Note that the running website will be accessing files in `WEBSITE_DIR`.
It is possible to edit files in `WEBSITE_DIR/catalog/static`
and `WEBSITE_DIR/catalog/template` directly and observe the effects.
Query-generated TSV files will appear here: `WEBSITE_DIR/catalog/static/tmp`.

To completely take the whole system down and rebuild,
it will need to be stopped (`bash catalog stop`),
the docker containers deleted (`bash catalog rm`),
the files deleted (`sudo rm -r WEBSITE_DIR`),
and rebuilt (`bash catalog all`).

## Command-line access to running docker containers

To get bash shell access to the website running in the container:
```
docker exec -it dev.ewascatalog bash
```

For debugging purposes, it may be useful to look at:
- web server (`docker exec -it dev.ewascatalog_srv`) logs in `/var/log/nginx`.
- mysql (`docker exec -it dev.ewascatalog_db`) files in: `/var/db/mysql/`.

## Database access port 

The files `docker/docker-compose.yml` and `settings.env`
refer to a port for accessing the MySQL database.
It should match ports referenced in 
`/etc/mysql/my.cnf` or `/etc/mysql/mysql.conf.d/mysqld.cnf`
of the container.

## Container IP address

The container IP address is typically '172.17.0.3', but
this can be verified:
```
docker inspect dev.ewascatalog | grep -e '"IPAddress"' | head -n 1 | sed 's/[^0-9.]*//g'
```

## Next steps

### To do

* Move repo over to the shark server and get it running as the main website.

* Not known how published EWAS summary statistics get from
  'published-ewas/study-files/' to the tables in
  'files/ewas-sub-stats/published/'.  

* Should have a command in the 'catalog' script for creating a backup of the
  container. Building is pretty quick except for installing R packages ...

* Update the acknowledgements section on the about page http://www.ewascatalog.org/about. Just need to add names to the template file.

* Contact PACE members for full summary statistics of already published articles. Try Gemma first and test out the upload page (see New features below)

* Add a feature to the EWAS Catalog R package that allows browsing of just the studies (e.g. the 'studies.txt' file in 'files/ewas-sub-stats/combined_data/').

* Should only generate downloadable files of summary statistics when the user requests, not every time a query is run. Currently, to save space these files get deleted when a new query is submitted which could cause problems!

* Update the 'in-house-ewas' pipeline so it matches the new 'upload' pipeline
	- Update the study file generation to match the new data
	- Update the scripts used in `bash catalog check-new-upload` and `bash catalog update-database` to incorporate in-house ewas 
    
### New features

* Enrichment test for a set of CpG sites

* Create an upload page for full summary statistics. This should contain: Clear details on how to access the full dataset (data will be put on Zenoto and have a DOI), some boxes to fill in for the study details, an upload button (with details on format data needs to be in).

