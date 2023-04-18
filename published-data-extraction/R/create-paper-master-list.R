# --------------------------------------------
# Creating a master spreadsheet of papers checked
# --------------------------------------------

# aim of script is to bring together the data from recruits to see what
# papers have been extracted since the data extraction team was formed

# pkgs
library(tidyverse) # tidy code + data
library(readxl) # read in excel files
library(openxlsx) # write out excel files
library(lubridate) # formatting dates

# --------------------------------------------
# Reading in relevant files
# --------------------------------------------

## 1. Data in catalog
FILE_DIR <- "../../files"
current_data_path <- file.path(FILE_DIR, "ewas-sum-stats/combined_data/studies.txt")
current_data <- read_tsv(current_data_path, guess_max = 1e6)
# web_file <- "http://ewascatalog.org/static//docs/ewascatalog-studies.txt.gz"
# current_data <- read_tsv(web_file, guess_max = 1e6)

## 2. Previous master list
master_file <- "data-to-enter/master-extraction-list.xlsx"
if (file.exists(master_file)) {
	master_dat <- read_xlsx(master_file)
	master_dat$date <- as.character(master_dat$date)
}

## 3. all other extractions
file_pattern <- "papers-to-add"
assigned_files <- dir("recruits-data", recursive=TRUE, full.names=TRUE, pattern=file_pattern)

# remove the study assignments and example
assigned_files <- assigned_files[!grepl("\\/study-assignments\\/", assigned_files)]
assigned_files <- assigned_files[!grepl("\\/00-example-folder\\/", assigned_files)]

# read files function
read_files <- function(file_name, keep_cols)
{
	message(file_name)
	x <- read_xlsx(file_name) # don't change this to assigning col_types or the date column will be wrong
	if (nrow(x) == 0) return(NULL)
	colnames(x) <- tolower(colnames(x))
	x$date <- as.character(x$date)
	x$pmid <- as.character(x$pmid)
	x$comments <- as.character(x$comments)
	x <- x[, keep_cols]
	if (any(is.na(x[["added (y/n)"]]))) warning("Check whether the papers have been added in this file: ", file_name)
	# if ("n" %in% colnames(x)) x <- x[, colnames(x) != "n"]
	return(x)
}

# system(paste("open", "recruits-data/Paul\\ Yousefi/2021-05-24/papers-to-add-2021-05-24.xlsx"))

# read in all files
cols_to_keep <- c("pmid", "date", "title", "assigned_to", "added (y/n)", "comments")
recruit_data <- map_dfr(assigned_files, read_files, keep_cols = cols_to_keep)

pm <- "34091768"
## remove NAs
recruit_data <- dplyr::filter(recruit_data, !is.na(assigned_to))

## remove un-received external data from 2 months prior
external_files <- dir("external-data", recursive=TRUE, full.names=TRUE, pattern=file_pattern)
external_data <- map_dfr(external_files, function(x) {out <- read_xlsx(x); out$contacted <- as.Date(out$contacted); return(out)})
get_date_diff <- function(date1 = today(), date2)
{
	x <- interval(date1, as.Date(date2))
	x %/% months(1)
}

unreceived_data <- external_data %>%
	mutate(date_diff = get_date_diff(date2 = contacted)) %>%
	dplyr::filter(data_received == "N" & date_diff < -2)

## get duplicated pmids as these indicate that contacting the authors was unsuccessful, and one of the team ran the analyses
dup_pmids <- unreceived_data %>%
	dplyr::filter(sum(PMID %in% recruit_data$pmid) > 1) %>%
	pull(PMID)

## Remove the individual who collects author data from recent papers
ind <- "Paul Yousefi"

recruit_data <- recruit_data %>%
	dplyr::filter(!(pmid %in% dup_pmids & assigned_to == ind)) %>%
	dplyr::filter(!(pmid %in% unreceived_data$PMID & !pmid %in% dup_pmids))

# --------------------------------------------
# Join it all together
# --------------------------------------------

## format data in catalog
form_catalog_data <- current_data %>%
	dplyr::select(pmid = PMID, date = Date) %>%
	mutate(date = as.character(date), 
		   assigned_to = "old recruitment team", `added (y/n)` = "Y", comments = NA)

## put all data together 
comb_data <- bind_rows(list(master_dat, recruit_data, form_catalog_data)) %>%
	dplyr::filter(!duplicated(pmid))

## sort out the date formats
comb_data$date <- parse_date_time(x = comb_data$date,
                orders = c("Ymd", "Y-m-d", "d/m/y")) %>%
                as.Date

sum(comb_data$assigned_to == "old recruitment team")

write.xlsx(comb_data, file = master_file, overwrite = TRUE)
