# ------------------------------------------------------------
# Fixing EC data 2021-08-16
# ------------------------------------------------------------

## Aim: Fix all things fixable from catalog-data-checks-2021-08-16.html

## NB: Run this script where local ewas catalog files are stored. If not stored locally then copy from RDSF
##     to local space and run the script

## pkgs
library(tidyverse) # tidy code and data
library(lubridate) # Date fixes

## data
web_studies <- read_tsv("http://www.ewascatalog.org/static//docs/ewascatalog-studies.txt.gz", guess_max = 1e6)
web_results <- read_tsv("http://www.ewascatalog.org/static//docs/ewascatalog-results.txt.gz", guess_max = 1e6)
local_studies_file <- "../local-webapp/files/ewas-sum-stats/combined_data/studies.txt"
local_results_file <- "../local-webapp/files/ewas-sum-stats/combined_data/results.txt"
studies <- read_tsv(local_studies_file, guess_max = 1e6)
results <- read_tsv(local_results_file, guess_max = 1e6)

# ------------------------------------------------------------
# Check local and web data are the same
# ------------------------------------------------------------

## This is very important before making changes!!
if (!all.equal(web_studies, studies)) {
	stop("Local studies and downloadable studies from the website are not the same!")
} else if (!all.equal(results, web_results)) {
	stop("Local results and downloadable results from the website are not the same!")
} else {
	message("All goooood")
	rm(list = c("web_results", "web_studies"))
}

# ------------------------------------------------------------
# Duplication fixes
# ------------------------------------------------------------

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

## Just duplicated results? 
dup_res
distinct(dup_res) # YES

## Remove duplications
studies <- distinct(studies)
results <- distinct(results)

# ------------------------------------------------------------
# PMID fixes
# ------------------------------------------------------------

## All good here :) 

# ------------------------------------------------------------
# EFO fixes
# ------------------------------------------------------------

## All good here :) 

# ------------------------------------------------------------
# Date fixes
# ------------------------------------------------------------

### Format fixes
n_missing <- sum(is.na(studies$Date))

## Want dates to be in YYYY-mm-dd. They're currently in YYYY-mm-dd, dd/mm/YYYY and mm-dd-YYYY

## Changing dd-mm-YYYY dates
daymy_pmids <- c("33239103", "32958748")
daymy_new_studies <- studies %>%
	dplyr::filter(PMID %in% daymy_pmids) %>%
	mutate(Date = format(strptime(Date, "%d/%m/%Y"), "%Y-%m-%d"))

new_studies <- studies %>%
	dplyr::filter(!PMID %in% daymy_pmids) %>%
	bind_rows(daymy_new_studies)

## Sanity check
all(new_studies$StudyID %in% studies$StudyID)
# TRUE
studies <- new_studies

## Changing mm-dd-YYYY dates
yearmd <- ymd(studies$Date)
mondy <- mdy(studies$Date) 
yearmd[is.na(yearmd)] <- mondy[is.na(yearmd)]

## Update the studies file
tail(studies$Date, n = 10)
studies$Date <- yearmd
tail(studies$Date, n = 10)

## Check still same number of missing vals
stopifnot(sum(is.na(studies$Date)) == n_missing)

# ------------------------------------------------------------
# Inclusion criteria fixes
# ------------------------------------------------------------

## All good here :) 

# ------------------------------------------------------------
# Write out the data
# ------------------------------------------------------------

write.table(studies, file = local_studies_file, col.names = T, row.names = F, quote = F, sep = "\t")
write.table(results, file = local_results_file, col.names = T, row.names = F, quote = F, sep = "\t")
