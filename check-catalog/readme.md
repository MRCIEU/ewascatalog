# Checking the catalog data

Humans make mistakes, even the great Thomas Battram, so some of the data in The EWAS Catalog might not be quite right. Here we hope to try and identify some mistakes in the data. See [`report`](report) for any reports relating to the data.

## Workflow

Clone the repo first.

If you don't have snakemake installed then go to the website: https://snakemake.readthedocs.io/en/stable/getting_started/installation.html and install it.

When you have it installed and have activated it, e.g. with `conda activate snakemake`, run the commands below:

``` bash
# conda activate snakemake-tutorial
## Dry run
snakemake -nrp
## Run pipeline
snakemake -rp --cores 1
```

If any errors crop up then solve them. Example script can be found in [`fixes-2021-08-16.R`](R/fixes-2021-08-16.R). If the website is running locally then you can upload the new data to the local version, change the "params" under "rule download_files" in the [`Snakefile`](Snakefile) and re-run the commands above to test if the changes have worked before uploading to the catalog. If not then you'll have to just upload the data to public-facing website and then re-run the commands. __NOTE:__ if you do this on the same day as you made the original report then you'll have to rename the original report before re-running the snakemake commands.

If you need to update the database then follow the instructions in the [database](../database/readme.md) directory (under the section `Direct access to the database`) to remove the "results" and the "studies" tables from the MySQL database.