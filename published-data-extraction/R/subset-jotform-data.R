# ------------------------------------------------------------
# Get PMIDs from all "papers-to-add" spreadsheets
# ------------------------------------------------------------

library(tidyverse)
library(readxl)
library(openxlsx)

args <- commandArgs(trailingOnly = TRUE)
recruitpath <- args[1]
date <- args[2]
rawfile <- args[3]
outfile <- args[4]
debugfile <- args[5]

# recruitpath <- "recruits-data"
# date <- "2021-09-27"
# rawfile <- "recruits-data/combined-data/2021-09-27/jotform-rawdata-all.xlsx"
# outfile <- "recruits-data/combined-data/2021-09-27/jotform-rawdata.xlsx"
# debugfile <- "recruits-data/combined-data/2021-09-27/people-pmid.xlsx"

jotform_dat <- read_xlsx(rawfile)

files <- list.files(recruitpath, recursive = TRUE)
filename_of_interest <- paste0("papers-to-add-", date, ".xlsx")
files_of_interest <- grep(filename_of_interest, files, value = T)

message("papers-to-add files found:\n", paste(files_of_interest, collapse = "\n"))

recruits <- readLines(file.path(recruitpath, "recruits.txt"))
recruits <- trimws(recruits)

## rm paul
files_of_interest <- files_of_interest[-grep("Paul", files_of_interest)]
pmids <- map_dfr(files_of_interest, function(pfile) {
	dat <- read_xlsx(file.path(recruitpath, pfile))
	rec <- str_extract(pfile, paste(recruits, collapse = "|"))
	out <- tibble(recruit = rec, pmid = as.character(dat$pmid))
	return(out)
})

pmids <- pmids %>%
	dplyr::filter(!is.na(pmid))

## output people and pmids for sake of 
write.xlsx(pmids, file = debugfile)

outjotform <- jotform_dat %>%
	dplyr::filter(`PubMed ID` %in% pmids$pmid)

write.xlsx(outjotform, file = outfile)