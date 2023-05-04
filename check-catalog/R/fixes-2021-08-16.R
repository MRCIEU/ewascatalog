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
FILE_DIR <- ""
web_studies <- read_tsv("http://www.ewascatalog.org/static//docs/ewascatalog-studies.txt.gz")
web_results <- read_tsv("http://www.ewascatalog.org/static//docs/ewascatalog-results.txt.gz")
local_studies_file <- file.path(FILE_DIR, "ewas-sum-stats/combined_data/studies.txt")
local_results_file <- file.path(FILE_DIR, "ewas-sum-stats/combined_data/results.txt")
studies <- read_tsv(local_studies_file)
results <- read_tsv(local_results_file)

# ------------------------------------------------------------
# Check local and web data are the same
# ------------------------------------------------------------

## This is very important before making changes!!
stud_ae <- all.equal(web_studies, studies)
res_ae <- all.equal(web_results, results)
if (!isTRUE(stud_ae)) {
	stop("Local studies and downloadable studies from the website are not the same!\n",
		  "output from all.equal() is:\n", stud_ae)
} else if (!isTRUE(res_ae)) {
	stop("Local results and downloadable results from the website are not the same!\n",
		  "output from all.equal() is:\n", res_ae)
} else {
	message("All goooood")
	rm(list = c("web_results", "web_studies"))
}

# ------------------------------------------------------------
# Duplication fixes
# ------------------------------------------------------------

## Nothing here to fix :D 

# ------------------------------------------------------------
# PMID fixes
# ------------------------------------------------------------

studies[studies$Author == "Rijlaarsdam J",]
studies[studies$Author == "Rijlaarsdam J" & is.na(studies$PMID), "PMID"] <- "33494854"
studies[studies$Author == "Sammallahti S",]
studies[studies$Author == "Sammallahti S" & is.na(studies$PMID), "PMID"] <- "33414500"

# ------------------------------------------------------------
# EFO fixes
# ------------------------------------------------------------

## Remember that traits can have more than one EFO!

hba1c_ids <- c("26643952_hba1c_basicmar_1",  "26643952_hba1c_basicmar_2")
hba1c_efo <- "EFO_0004541" # EFO is for HbA1c measurement
studies[studies$StudyID %in% hba1c_ids, "EFO"] <- hba1c_efo

subs_id <- "27922636_substance_use_dna_methylation_at_birth"
subs_efo <- gsub("EFO_000432", "EFO_0004329", studies[studies$StudyID == subs_id, "EFO", drop=T]) # New EFO is for alcohol drinking
studies[studies$StudyID == subs_id, "EFO"] <- subs_efo

# ------------------------------------------------------------
# Date fixes
# ------------------------------------------------------------

### Format fixes

n_missing <- sum(is.na(studies$Date))

## Code below works if dates are in format dd/mm/yyyy - change accordingly 
yearmd <- ymd(studies$Date)
daymy <- dmy(studies$Date) 
yearmd[is.na(yearmd)] <- daymy[is.na(yearmd)]

## Update the studies file
studies$Date <- yearmd

## Check still same number of missing vals
stopifnot(sum(is.na(studies$Date)) == n_missing)

### Manual fixes
ss_date_ids <- c("Sammallahti-S_maternal_anxiety_during_pregnancy_meta-analysis,_using_450k-only_sites", 
				 "Sammallahti-S_maternal_anxiety_during_pregnancy_meta-analysis_using_epic-only_sites", 
				 "Sammallahti-S_maternal_pregnancy-related_anxiety_during_pregnancy_meta-analysis_using_450k-only_sites")
ss_date <- as.Date("2021-01-07")
studies[studies$StudyID %in% ss_date_ids, "Date"] <- ss_date

# ------------------------------------------------------------
# Inclusion criteria fixes
# ------------------------------------------------------------

## Waiting to discuss (as of 2021-08-16)

## Remove all studies with n < 100 (except Gemma's)
gemma_studs <- studies %>% 
	dplyr::filter(Author == "Sharp GC") %>%
	pull(StudyID)

studies_to_rm <- studies %>%
	dplyr::filter(N < 100) %>%
	pull(StudyID)
studies_to_rm <- studies_to_rm[!studies_to_rm %in% gemma_studs]
studies <- studies %>%
	dplyr::filter(!StudyID %in% studies_to_rm)

## Remove all results with P > 1e-4
results <- results %>%
	dplyr::filter(StudyID %in% studies$StudyID) %>%
	dplyr::filter(P < 1e-4)

## Remove studies with no results 
studies <- studies %>%
	dplyr::filter(StudyID %in% results$StudyID)

# ------------------------------------------------------------
# Write out the data
# ------------------------------------------------------------

write.table(studies, file = local_studies_file, col.names = T, row.names = F, quote = F, sep = "\t")
write.table(results, file = local_results_file, col.names = T, row.names = F, quote = F, sep = "\t")
