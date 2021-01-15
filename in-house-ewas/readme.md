# Scripts for in-house EWAS for the catalog

These scripts are for extracting and cleaning phenotype data, cleaning DNA methylation data and then running EWAS in ARIES and for some phenotype data in GEO. The phenotype data for GEO was already extracted by Dr. Paul Yousefi using [geograbi](https://github.com/yousefi138/geograbi).

To use these scripts a text file or shell script must be created in this directory called "filepaths.sh" with all the filepaths and files needed. A template can be found at __filepaths_template.sh__.

The scripts are performed locally or on bluecrystal, a (__L__) or (__BC__) will be used to indicate this.

rdsf space used for the results and alspac data: /projects/MRC-IEU/research/projects/ieu1/wp2/004/working/data/

Functions used across scripts sourced at the start of each R script found in __useful_functions.R__

## ALSPAC

* ALSPAC data are extracted using __alspac_data_extraction.R__, which saves the data in the RDSF in an encrypted file. (__L__)
* This data will need to be copied from the RDSF space to the bluecrystal space for further analysis.
* PCs are generated using __aries_pca.sh__ (__BC__)
* The aries DNA methylation data is cleaned in __clean_aries_meth.R__ (__BC__)
* Outliers are removed from phenotypes and covariates are combined with phenotype data in __combine_traits_and_covariates.R__ (__BC__)

## GEO

__NOTE__ There are 2 steps before using the scripts:

1. GEO data need to be extracted. This was done using [geograbi](https://github.com/yousefi138/geograbi).
2. The data need to be manually asssessed to see whether they are suitable for the catalog and saved.

These data can be found in the geo rdsf space: /projects/MRC-IEU/research/projects/ieu2/p5/020/working

* GEO data are assessed using __geo_phenotype_sorting.R__ and __manual_geo_phenotype_sorting.R__ (__BC__)
* The studies files should be manually edited 
* The methylation data that will be used will need to be moved over from the RDSF to the bluecrystal space
* The DNA methylation data is checked using __clean_geo_meth.R__ (__BC__)

## EWAS and downstream formatting

* The ewas for either cohort can be run using __ewas_script.R__, which uses the package [ewaff](https://github.com/perishky/ewaff) for the analyses. (__BC__)
* The EWAS results are formatted for the catalog using __format_ewas_for_catalog.R__ (__BC__)
* These results are moved to the RDSF space
* The study meta data are formatted for the catalog with __format_for_catalog.R__ (__L__)

* After running __format_for_catalog.R__ all the results should be in the correct format and in the correct files folder space so they can be added to the catalog by running `bash catalog update-database`

## Finished data

All the data can be found in the cohort directories (alspac/ or geo/) within the rdsf space. 

## Issues

* Need to re-format how the studies files are made. Ideally everything should be able to be run through the same code as the published data (`bash catalog prep-inhouse-data` and then `bash catalog update-database`). This means:
	+ Changing scripts so the studies file is produced at the end of data cleaning phase (with gaps for things that won't be known until after the EWAS like sample size)
	+ Re-formatting __ewas_script.R__
* Directories will need to be updated or code changed when more ARIES timepoints are added (essentially each timepoint will have to be treated as a different cohort with the current code!)
* There is currently no code to easily move files to and from the RDSF, will add this later!
* Study IDs should be PMID_author_trait, but the trait names were funny for GEO datasets so have been manually altered post-EWAS. So the study IDs for some GEO datasets don't contain the trait name.
