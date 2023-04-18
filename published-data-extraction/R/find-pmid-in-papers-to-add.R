## Find a PMID in papers to add

library(tidyverse)
library(readxl)

## Read in all other papers-to-add spreadsheets
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
	# if ("n" %in% colnames(x)) x <- x[, colnames(x) != "n"]
	return(x)
}

# read in all files
cols_to_keep <- c("pmid", "date", "title", "assigned_to", "added (y/n)", "comments")
recruit_data <- map_dfr(assigned_files, read_files, keep_cols = cols_to_keep)


pmid_to_find <- "32745807"
recruit_data %>%
	dplyr::filter(pmid == pmid_to_find)