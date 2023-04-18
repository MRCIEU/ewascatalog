#
#
#


# pkgs
library(tidyverse) # tidy code and data
library(readxl) # reading in excel files
library(openxlsx) # writing out excel file

## CHANGE ME
date_of_extraction <- "2022-07-25"

mkdir <- function(path) system(paste("mkdir -p", path))
mkdir(paste0("recruits-data/combined-data/", date_of_extraction))
mkdir(paste0("recruits-data/combined-data/", date_of_extraction, "/results"))

### This should be done after results are manually scanned

# 1. read in recruits
recruits <- trimws(readLines("recruits-data/recruits.txt"))
# a. remove individual who is gathering author names 
ind <- c("Paul Yousefi") # REMEMBER TO ADD ABI HERE FOR 2022-04-25!!!
recruits <- recruits[!recruits %in% ind]

# 2. make function that reads in the studies files for a given recruit
# 	a. and moves results files into the results folder
combine_studies <- function(recruits, date)
{
	map_dfr(recruits, function(rec) {
		print(rec)
		rec_path <- file.path("recruits-data", rec, date)
		studies_file <- file.path(rec_path, "studies.xlsx")
		if (!file.exists(studies_file)) {
			warning("The studies file: ", studies_file, " does not exist. Check to make sure this is intentional.")
			return(NULL)
		}
		studies <- read_xlsx(studies_file)
		if (nrow(studies) == 0) return(NULL)
		studies$recruit <- rec
		studies$Date <- as.character(studies$Date)
		studies$PMID <- as.character(studies$PMID)
		# copy results over
		res_path <- file.path(rec_path, "results")
		res_files <- list.files(res_path)
		res_dirs <- list.dirs(path = res_path, full.names = TRUE, recursive = FALSE)
		out_path <- file.path("recruits-data/combined-data", date, "results")
		if (length(res_dirs) > 0) {
			# get dir names
			dir_nams <- gsub(paste0(res_path, "/"), "", res_dirs)
			# copy files into correct directories
			lapply(dir_nams, sort_dir, res_path = res_path, out_path = out_path)
			# remove directory from file list
			res_files <- res_files[!res_files %in% dir_nams]
		}
		x <- file.copy(from = file.path(res_path, res_files), 
					   to = out_path, 
					   overwrite = TRUE, 
					   recursive = FALSE, 
					   copy.mode = TRUE)
		stopifnot(sum(x) == length(res_files))
		# return studies
		return(studies)
	})
}
rec <- recruits[6]
# 2 b. make function to sort out the directories in any results folder
sort_dir <- function(dir_nam, res_path, out_path) 
{
	# make dir in new file path
	mkdir(file.path(out_path, dir_nam))
	# move files there
	res_dir_files <- list.files(file.path(res_path, dir_nam))
	x <- file.copy(from = file.path(res_path, dir_nam, res_dir_files), 
				   to = file.path(out_path, dir_nam), 
	          	   overwrite = TRUE, recursive = FALSE, 
	         	   copy.mode = TRUE)
	stopifnot(sum(x) == length(res_dir_files))
}

# 3. combine studies data (and make sure people are attributed to each row)
comb_studies <- combine_studies(recruits, date = date_of_extraction)

# 4. remove missing rows
comb_studies <- comb_studies[rowSums(is.na(comb_studies)) != ncol(comb_studies) - 1, ]

# 5. read in jotform studies
jotform_file <- file.path("recruits-data/combined-data", date_of_extraction, "studies-jotform.xlsx")
if (file.exists(jotform_file)) {
	jotform_studies <- read_xlsx(jotform_file)
	jotform_studies$recruit <- "jotform"
	jotform_studies$PMID <- as.character(jotform_studies$PMID)
	if (ncol(comb_studies) == 0) {
		studies_out <- jotform_studies
	} else {
		comb_studies$PMID <- as.character(comb_studies$PMID)
		if (!all(colnames(jotform_studies) %in% colnames(comb_studies))) stop("column names of 'studies-jotform.xlsx' does not match those from recruit uploaded 'studies.xlsx'")
		studies_out <- bind_rows(comb_studies, jotform_studies)
	}
} else {
	studies_out <- comb_studies
}

## Remove age group category definitions
studies_out$Age_group <- gsub(" \\(.*", "", studies_out$Age_group)

# remove recruit names from one set of studies
studies_no_names <- studies_out %>%
	dplyr::select(-recruit)

# 6. write out the combined studies file
write.xlsx(studies_no_names, 
		   file = file.path("recruits-data/combined-data", date_of_extraction, "studies.xlsx"), 
		   sheetName = "data")

write.xlsx(studies_out, 
		   file = file.path("recruits-data/combined-data", date_of_extraction, "studies-with-names.xlsx"), 
		   sheetName = "data")
