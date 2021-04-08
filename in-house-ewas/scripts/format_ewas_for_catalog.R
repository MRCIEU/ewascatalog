# --------------------------------------------------------
# Script for formatting EWAS results for the catalog
# --------------------------------------------------------

# Just format results so they're ready for pipeline:
# 1. Bind all the meta files together for the studies file
# 2. Loop through the studies and extract data at P<1e-4
# 3. Tidy up studies file and output results into a "results/" directory

pkgs <- c("tidyverse", "openxlsx")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")
source("scripts/useful_functions.R")
read_filepaths("filepaths.sh")

args <- commandArgs(trailingOnly = TRUE)
cohort <- args[1]
# cohort <- "alspac"
# cohort <- "geo"

# res_dir <- paste0(local_rdsf_dir, "data/", cohort, "/results/")
res_dir <- file.path("results", cohort)
if (!file.exists(res_dir)) stop("File path not found!")

# file paths 
raw_path <- file.path(res_dir, "raw")
derived_path <- file.path(res_dir, "derived")

extra_cohort_dirs <- list.files(raw_path)

# --------------------------------------------------------
# Bind studies files together
# --------------------------------------------------------
di=extra_cohort_dirs[1]
meta_dat <- map_dfr(extra_cohort_dirs, function(di) {
	meta_files <- grep("catalog_meta_data", list.files(file.path(raw_path, di)), value=T)
	if (length(meta_files) == 0) return(NULL)
	meta_out <- map_dfr(meta_files, function(f) {
		out <- read_tsv(file.path(raw_path, di, f))
		system(paste0("rm ", raw_path, "/", di, "/", f))
		return(out)
	})
	return(meta_out)
})

comb_file_nam <- file.path(derived_path, "combined_meta_data.txt")

if (file.exists(comb_file_nam)) {
	current_meta_dat <- read_tsv(comb_file_nam)
	meta_dat <- bind_rows(current_meta_dat, meta_dat) %>%
		distinct()
}

write.table(meta_dat, file = comb_file_nam, 
			col.names = T, row.names = F, quote = F, sep = "\t")

# --------------------------------------------------------
# Check EWAS that have failed 
# --------------------------------------------------------

# extract those phens that failed in the EWAS stage
ewas_failed_phens <- lapply(extra_cohort_dirs, function(di) {
	failed_files <- grep("failed_ewas", list.files(file.path(raw_path, di)), value=T)
	if (length(failed_files) == 0) return("")
	failed_out <- lapply(failed_files, function(f) {
		out <- readLines(file.path(raw_path, di, f))
		system(paste0("rm ", raw_path, "/", di, "/", f))
		return(out)
	})
	return(failed_out)
})
ewas_failed_phens <- unlist(unlist(ewas_failed_phens))

# extract those that failed due to another technical issue
old_meta_dat <- map_dfr(extra_cohort_dirs, function(di) {
	meta_file <- file.path("data", cohort, di, "phenotype_metadata.txt")
	read_tsv(meta_file)
})

other_failed_phens <- old_meta_dat %>%
	dplyr::filter(!phen %in% meta_dat$phen) %>%
	pull(phen)

all_failed_phens <- unique(c(ewas_failed_phens, other_failed_phens))

all_failed_phens <- all_failed_phens[!all_failed_phens %in% meta_dat$phen]

write.table(all_failed_phens, file = file.path(derived_path, "combined_failed_ewas.txt"), 
			col.names = F, row.names = F, quote = F, sep = "\n")

message("Figure out why the EWAS for these phenotypes failed!!")

# --------------------------------------------------------
# Make final studies file!
# --------------------------------------------------------
studies_columns <- c("Author", "Cohorts_or_consortium", "PMID", "Date", "Trait", 
					 "EFO", "Trait_units", "dnam_in_model", "dnam_units", 
					 "Analysis", "Source", "Covariates", "Methylation_Array", 
					 "Tissue", "Further_Details", "N", "N_Cohorts", "Age_group", "Sex",
					 "Ethnicity", "Results_file")

format_num <- function(x) as.numeric(format(x, digits = 4, big.mark = ""))

format_res <- function(df)
{
	df %>%
		mutate(Beta = format_num(Beta), 
			   SE = format_num(SE), 
			   P = format_num(P))
}

out_res_path <- file.path(derived_path, "results")
if (!file.exists(out_res_path)) system(paste("mkdir", out_res_path))
out_full_res_path <- file.path(derived_path, "full_stats")
if (!file.exists(out_full_res_path)) system(paste("mkdir", out_full_res_path))

# for umlaut values 
# meta_dat[190, "phen"] <- "Anti_Mullerian_hormone__AMH__ng_ml__FOM1"
# meta_dat[190, "full_stats_file"] <-"results/alspac/raw/FOM/full_stats/Anti_Müllerian_hormone__AMH__ng_ml__FOM1.txt"

studies_full <- map_dfr(1:nrow(meta_dat), function(x) {
	print(x)
	df <- meta_dat[x, ]
	# read in full stats and format
	full_dat <- read_tsv(df$full_stats_file) %>%
		rename(CpG = probeID, Beta = estimate, SE = se, P = p.value) %>%
		format_res
	# get P<1e-4
	derived_dat <- full_dat %>%
		dplyr::filter(P < 1e-4)	
	# extract data for studies file
	studies_out <- df %>%
		dplyr::select(one_of(studies_columns))	
	# write out derived results if any present
	if (nrow(derived_dat) == 0) {
		studies_out$keep <- FALSE
	} else {
		# write out results to already determined results file
		write.csv(derived_dat, file = file.path(out_res_path, df$Results_file), 
			  row.names = F, quote = F)
		studies_out$keep <- TRUE
	}
	# write out the full data to full res path
	full_dat <- full_dat[, c("CpG", "Beta", "SE", "P")]
	write.csv(full_dat, file = file.path(out_full_res_path, df$Results_file), 
			  row.names = F, quote = F)
	return(studies_out)
})

studies <- studies_full %>%
	dplyr::filter(keep) %>%
	dplyr::select(-keep)

studies_full <- studies_full %>%
	dplyr::select(-keep)

# write out full studies data for upload to zenodo
write.csv(studies_full, file = file.path(derived_path, "studies-full.csv"), 
		  row.names = FALSE, quote = TRUE)

# write out studies data for upload to the catalog
write.xlsx(studies, file = file.path(derived_path, "studies.xlsx"), 
		   sheetName = "data")

