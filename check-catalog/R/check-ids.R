# --------------------------------------------------------
# Check PMIDs and StudyIDs
# --------------------------------------------------------

## pkgs
library(tidyverse) # tidy data and code

## args
args <- commandArgs(trailingOnly = TRUE)
studies_file <- args[1]
results_file <- args[2]
outfile <- args[3]

# studies_file <- "data/studies.txt.gz"
# results_file <- "data/results.txt.gz"
# outfile <- "data/bad-ids.RData"

## data
studies <- read_tsv(studies_file, guess_max = 1e6)
results <- read_tsv(results_file, guess_max = 1e6)

# --------------------------------------------------------
# Check the PMIDs
# --------------------------------------------------------

# check all studies without a pmid are in house studies
no_pmid_studies <- studies %>%
	dplyr::filter(is.na(PMID) & Author != "Battram T") 

# --------------------------------------------------------
# Check StudyIDs
# --------------------------------------------------------

dup_studid <- studies %>%
	dplyr::filter(duplicated(StudyID)) %>%
	pull(StudyID) %>%
	unique

dup_studies <- studies %>%
	dplyr::filter(StudyID %in% dup_studid)

dup_res <- results %>%
	dplyr::filter(StudyID %in% dup_studid) %>%
	dplyr::select(CpG, P, StudyID)

# should be TRUE if just duplications in studies data that are full duplications - i.e. not just the studyid
full_dup <- nrow(dup_res) == nrow(distinct(dup_res)) 

# --------------------------------------------------------
# Write it out
# --------------------------------------------------------

out <- list(no_pmid_studies = no_pmid_studies, 
			dup_studies = dup_studies, 
			full_dup = full_dup)

save(out, file = outfile)