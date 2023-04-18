# --------------------------------------------------------
# Formatting dates
# --------------------------------------------------------

## pkgs
library(tidyverse) # tidy data and code
library(lubridate) # tidy data and code

## get data
studies <- read_tsv("http://www.ewascatalog.org/static//docs/ewascatalog-studies.txt.gz", guess_max=1e6)

sum(is.na(studies$Date)) # 3

## Reformat the two likely date formats (YYYY-mm-dd and dd/mm/YYYY) to the correct format (YYYY-mm-dd)
yearmd <- ymd(studies$Date)
daymy <- dmy(studies$Date) 
yearmd[is.na(yearmd)] <- daymy[is.na(yearmd)]

## Update the studies file
studies$Date <- yearmd

## Write out the studies file
outfile <- ""
write.table(studies, file = outfile, row.names = F, col.names = T, quote = F, sep = "\t")

## Check still same number of missing vals
sum(is.na(studies$Date)) # 3
