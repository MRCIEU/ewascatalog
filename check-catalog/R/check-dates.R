# --------------------------------------------------------
# Check dates
# --------------------------------------------------------

## pkgs
library(tidyverse) # tidy data and code
library(lubridate) # dates and times made easy

## args
args <- commandArgs(trailingOnly = TRUE)
studies_file <- args[1]
outfile <- args[2]

# studies_file <- "data/studies.txt.gz"
# outfile <- "data/bad-dates.RData"


## data
studies <- read_tsv(studies_file)

# --------------------------------------------------------
# Check format of dates
# --------------------------------------------------------

## Check format of dates is yyyy-mm-dd
bad_dates <- is.na(parse_date_time(studies$Date, orders = "ymd"))
bad_date_studies <- studies[bad_dates, ]

## Check if likely date values of bad ones are dd/mm/yyyy
daymy <- dmy(bad_date_studies$Date) 

## save it oot
out <- list(bad_date_studies = bad_date_studies, 
			proposed_new_dates = daymy)

save(out, file = outfile)

