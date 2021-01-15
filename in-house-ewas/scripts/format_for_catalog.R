# ----------------------------------------
# formatting ewas results for the catalog
# ----------------------------------------

pkgs <- c("tidyverse", "readxl", "openxlsx")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")
source("scripts/useful_functions.R")
read_filepaths("filepaths.sh")

args <- commandArgs(trailingOnly = TRUE)
cohort <- args[1]
# cohort <- "alspac/FOM"
# cohort <- "geo"

res_dir <- paste0(local_rdsf_dir, "data/", cohort, "/results/")

if (!file.exists(res_dir)) stop("File path not found!")

# file paths 
raw_path <- paste0(res_dir, "raw/")
derived_path <- paste0(res_dir, "derived/")

extra_cohort_dirs <- list.files(raw_path) # This should just be directories!

# making temp directory for excel files to be moved over to the 
# rdsf because it is so bloody slow to write and edit in rdsf
temp_dir <- "temp"
make_dir(temp_dir)

dir=extra_cohort_dirs[1]
raw_met_file <- "catalog_meta_data.txt"
derived_met_file <- "catalog_meta_data.xlsx"

# Data from GEO dataset: 

# -------------------------------------------------
# Edit characteristics files
# -------------------------------------------------

# manually edit meta data
# 1. add in efo terms
# 2. re-write further_details
# 3. Change trait names if needs be
# 4. Change categories if needs be
# 5. Change tissue if needs be
dir="GSE106648"
char <- map_lgl(extra_cohort_dirs, function(dir) {
	print(dir)
	dd_path <- paste0(derived_path, dir)
	dd_files <- list.files(dd_path)
	if (derived_met_file %in% dd_files) {
		return(TRUE)
	} else {
		temp_file_path <- file.path(temp_dir, derived_met_file)
		new_file_path <- file.path(derived_path, dir, derived_met_file)
		if (file.exists(temp_file_path)) {
			mv_cmd <- paste("mv", temp_file_path, new_file_path)
			system(mv_cmd)
			print("Moved!")
		} else {
			raw_dat <- file.path(raw_path, dir, raw_met_file)
			if (!file.exists(raw_dat)) return(FALSE)
			df <- read_tsv(file.path(raw_path, dir, raw_met_file))
			df$Further_Details <- dir # To make it easier for GEO further details
			write.xlsx(df, temp_file_path)
			open_cmd <- paste("open", temp_file_path)
			system(open_cmd)
			stop("Edit the spreadsheet and come back!")
		}
		return(TRUE)
	}
	
})
# should capture those that the EWAS worked!
extra_cohort_dirs <- extra_cohort_dirs[char]
# extra_cohort_dirs <- extra_cohort_dirs[extra_cohort_dirs != "GSE59592"]
temp <- file.path(derived_path, "GSE50660", derived_met_file)
system(paste("open", temp))

# bind meta-data together
studies <- map_dfr(extra_cohort_dirs, function(dir) {
	print(dir)
	dd_file <- file.path(derived_path, dir, derived_met_file)
	meta_dat <- read_xlsx(dd_file)
	return(meta_dat)
})

studies_nam <- paste0(derived_path, "full_studies.txt")
write.table(studies, file = studies_nam, 
			col.names = T, row.names = F, quote = F, sep = "\t")

# remove temporary directory
rm_cmd <- paste("rm -r", temp_dir)
system(rm_cmd)

# -------------------------------------------------
# Save sub files in catalog
# -------------------------------------------------

results_nam <- paste0(derived_path, "results.txt")
sub_res <- read_tsv(results_nam)

studies_nam <- paste0(derived_path, "full_studies.txt")
studies <- read_tsv(studies_nam)

sub_studies <- studies %>%
	dplyr::filter(StudyID %in% sub_res$StudyID)

sub_out_dir <- paste0("../files/ewas-sum-stats/sub/", cohort) 

sub_res_nam <- file.path(sub_out_dir, "results.txt")
sub_studies_nam <- file.path(sub_out_dir, "studies.txt")
nams <- c(sub_res = sub_res_nam, sub_studies = sub_studies_nam)
nam <- nams[2]
# This didn't work for some reason but worked when done manually...
lapply(nams, function(nam) {
	if (file.exists(nam)) {
		cols = FALSE
		append = TRUE
	} else {
		cols = TRUE
		append = FALSE
	}
	out <- get(names(nam))
	write.table(out, file = nam, col.names = cols, 
				row.names = F, quote = F, sep = "\t", append = append)
})



