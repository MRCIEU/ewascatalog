# --------------------------------------------------
# Check inclusion criteria of the data for The EWAS Catalog
# --------------------------------------------------

## pkgs
library(tidyverse) # tidy code and data
library(usefunc) # own package of useful functions (https://github.com/thomasbattram/usefunc)

## args
args <- commandArgs(trailingOnly = TRUE)
studies_file <- args[1]
results_file <- args[2]
outfile <- args[3]

# studies_file <- "data/studies.txt.gz"
# results_file <- "data/results.txt.gz"
# outfile <- "data/inclusion-criteria-checks.RData"

## data
studies <- read_tsv(studies_file)
results <- read_tsv(results_file)

# --------------------------------------------------
# Check results format
# --------------------------------------------------

bad_cpg_results <- results[!grepl("^c", results$CpG), ]
bad_cpgs <- unique(bad_cpg_results$CpG)

bad_cpg_ids <- bad_cpg_results$StudyID

neg_p_results <- results %>%
	dplyr::filter(P < 0)

neg_p_ids <- neg_p_results$StudyID

neg_se_results <- results %>%
	dplyr::filter(!is.na(SE)) %>%
	dplyr::filter(sign(SE) == -1)

neg_se_ids <- neg_se_results$StudyID

# --------------------------------------------------
# Check inclusion criteria
# --------------------------------------------------

## N >= 100
low_n_studies <- studies %>%
	dplyr::filter(N < 100)

high_n_studies <- studies %>%
	dplyr::filter(!StudyID %in% low_n_studies$StudyID)

low_n_results <- results %>%
	dplyr::filter(StudyID %in% low_n_studies$StudyID)

## p < 1e-4
high_p_results <- results %>% dplyr::filter(P >= 1e-4)

low_p_results <- results %>%
	dplyr::filter(P < 1e-4)

high_p_ids <- unique(high_p_results$StudyID)

## whole studies that would be removed if taking away these results
res_to_rm <- unique(results$StudyID)[!unique(results$StudyID) %in% unique(low_p_results$StudyID)]
length(res_to_rm)

new_study_ids <- intersect(unique(low_p_results$StudyID), high_n_studies$StudyID)

# --------------------------------------------------
# Save out relevant info
# --------------------------------------------------

out <- list(
			low_n_studies = low_n_studies, 
			n_low_n_results = nrow(low_n_results),
			n_high_p_studies = length(high_p_ids), 
			n_rm_high_p_studies = length(res_to_rm), 
			n_high_p_results = nrow(high_p_results), 
			bad_cpg_ids = bad_cpg_ids,
			neg_p_ids = neg_p_ids, 
			neg_se_ids = neg_se_ids 
		)

save(out, file = outfile)


