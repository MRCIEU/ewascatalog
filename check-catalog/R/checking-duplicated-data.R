# --------------------------------------------------
# So you've found some duplicated data....
# --------------------------------------------------

## Today is not your lucky day - dealing with it may be painful and you may have to go back to the literature!

## pkgs
library(tidyverse) # tidy code and data
library(usefunc) # personal package of useful functions

## data
studies_file <- ""
results_file <- ""
studies <- read_tsv(studies_file, guess_max = 1e6)
results <- read_tsv(results_file, guess_max = 1e6)

## looking at data
dup_studid <- studies %>%
	dplyr::filter(duplicated(StudyID)) %>%
	pull(StudyID) %>%
	unique

studies %>%
	dplyr::filter(StudyID %in% dup_studid) %>%
	dplyr::select(Author, PMID, Trait, Analysis, StudyID)

trunc_dup_studies <- studies %>%
	dplyr::filter(StudyID %in% dup_studid) %>%
	dplyr::select(Trait, Analysis, StudyID, Exposure_Units)

trunc_dup_studies
trunc_dup_studies %>% pull(StudyID)

dup_res <- results %>%
	dplyr::filter(StudyID %in% dup_studid) %>%
	dplyr::select(CpG, P, StudyID)

# should be TRUE if just duplications in studies data that are full duplications - i.e. not just the studyid
nrow(dup_res) == nrow(distinct(dup_res)) 

## MANUAL EDITS HERE

## If it's not clear from the above what the problems are then go through the duplications one-by-one
## Tip: check for accents!
trunc_dup_studies %>% as.data.frame

pmid <- ""
tab <- studies %>% dplyr::filter(PMID == pmid) %>% as.data.frame

studyid_to_rm <- c("")

## Remove duplicates that need to be removed
## MANUAL EDITS HERE

## Write out any edits