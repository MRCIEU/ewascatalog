# ------------------------------------------------------------
# Fixing EC data 2023-05-04
# ------------------------------------------------------------

## Aim: Fix all things fixable from catalog-data-checks-2023-05-04.html

## NB: Run this script where local ewas catalog files are stored. If not stored locally then copy from RDSF
##     to local space and run the script

## pkgs
library(tidyverse) # tidy code and data
library(lubridate) # Date fixes

## data
FILE_DIR <- "../../files"
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

studies[studies$Author == "Tobi EW",]
studies[studies$Author == "Tobi EW" & is.na(studies$PMID), "PMID"] <- "35104326"
studies[studies$Author == "Fernandez-Jimenez N",]
studies[studies$Author == "Fernandez-Jimenez N" & is.na(studies$PMID), "PMID"] <- "36446949"

# ------------------------------------------------------------
# EFO fixes
# ------------------------------------------------------------

## Remember that traits can have more than one EFO!
efo_mondo_dat <- read_csv("data/efo-changes-2023-05-04.csv")
replace_dat <- tibble(mondo = basename(efo_mondo_dat[["Mondo replacement"]]), 
					  efo = basename(efo_mondo_dat[["EFO term obsoleted"]]))

for (i in 1:nrow(replace_dat)) {
	efo <- replace_dat[i, "efo", drop=T]
	mondo <- replace_dat[i, "mondo", drop=T]
	bad_efo_studies <- grep(efo, studies$EFO)
	subs_efo <- gsub(efo, mondo, studies$EFO[bad_efo_studies])
	studies$EFO[bad_efo_studies] <- subs_efo
}

# ------------------------------------------------------------
# Date fixes
# ------------------------------------------------------------

### Format fixes

n_missing <- sum(is.na(studies$Date))

## Code below works if dates are in format dd/mm/yyyy - change accordingly
yearmd <- ymd(studies$Date)
daymy <- dmy(studies$Date)
monthdy <- mdy(studies$Date)
yearmd[is.na(yearmd)] <- daymy[is.na(yearmd)]
yearmd[is.na(yearmd)] <- monthdy[is.na(yearmd)]

## Check still same number of missing vals
stopifnot(sum(is.na(yearmd)) == n_missing)

## Update the studies file
studies$Date <- yearmd

### Manual fixes

# ------------------------------------------------------------
# Inclusion criteria fixes
# ------------------------------------------------------------


# ------------------------------------------------------------
# Write out the data
# ------------------------------------------------------------

write.table(studies, file = local_studies_file, col.names = T, row.names = F, quote = F, sep = "\t")
write.table(results, file = local_results_file, col.names = T, row.names = F, quote = F, sep = "\t")
