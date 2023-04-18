# ------------------------------------------------------------------
# Get summary of EWAS catalog data
# ------------------------------------------------------------------ 

## Aim: To quickly get some stats on The EWAS Catalog data for papers/posters etc.

## Date: 2021-08-16

## pkgs
library(tidyverse) # tidy code and data

## data
studies_url <- "http://www.ewascatalog.org/static//docs/ewascatalog-studies.txt.gz"
studies <- read_tsv(studies_url, guess_max = 1e6)

results_url <- "http://www.ewascatalog.org/static//docs/ewascatalog-results.txt.gz"
results <- read_tsv(results_url, guess_max = 1e6)

## NB: may want to check the data is clean. This should be done before it is uploaded anyway, but might want to double check

# ------------------------------------------------------------------
# Split data where necessary
# ------------------------------------------------------------------ 

geo_studies <- studies %>%
	dplyr::filter(Consortium == "GEO" & Author == "Battram T")

aries_studies <- studies %>%
	dplyr::filter(Consortium == "ARIES" & Author == "Battram T")

pub_studies <- studies %>%
	dplyr::filter(!StudyID %in% c(aries_studies$StudyID, geo_studies$StudyID))

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------ 

## Number of studies
n_studies <- length(unique(studies$PMID))
# GEO
n_geo_studies <- length(unique(geo_studies$PMID))
# ARIES
n_aries_studies <- length(unique(aries_studies$PMID))
# published
n_pub_studies <- n_studies - n_aries_studies - n_geo_studies

## Number of EWAS
n_ewas <- nrow(studies)
# GEO
n_geo_ewas <- nrow(geo_studies)
# ARIES
n_aries_ewas <- nrow(aries_studies)
# published
n_pub_ewas <- n_ewas - n_aries_ewas - n_geo_ewas

## Number of traits
efos <- unique(unlist(str_split(studies$EFO, ", ?")))
n_efos <- length(efos)

n_traits_no_efo <- studies %>%
	dplyr::filter(is.na(EFO)) %>%
	pull(Trait) %>%
	tolower() %>%
	unique() %>%
	length
n_traits <- n_efos + n_traits_no_efo

## Number of associations
get_n_assoc <- function(results, studyids = "all", p_threshold = 1e-4)
{
	if (studyids == "all") studyids <- results$StudyID
	n_assocs <- results %>%
		dplyr::filter(StudyID %in% studyids) %>%
		dplyr::filter(P < p_threshold) %>%
		nrow
	return(n_assocs)
}
n_associations <- get_n_assoc(results)
# GEO
n_geo_associations <- get_n_assoc(results, studyids = geo_studies$StudyID)
# ARIES
n_aries_associations <- get_n_assoc(results, studyids = aries_studies$StudyID)
# published
n_pub_associations <- n_associations - n_aries_associations - n_geo_associations
# efo only
n_efo_associations <- get_n_assoc(results, studyids = studies[!is.na(studies$EFO), "StudyID", drop=T])


## Number of cpgs
n_cpgs <- length(unique(results$CpG))

## Number of genes
all_genes <- unlist(strsplit(results$Gene, ";"))
n_genes <- length(unique(all_genes))
