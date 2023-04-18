# ------------------------------------------------
# Getting papers to add to the catalog 
# ------------------------------------------------

# uses data from the EWAS Atlas and Matt's papers collected for 
# the epi-epi journal club (https://github.com/perishky/journalclub)
# to construct a list of papers to add to the catalog

## assuming in directory "ewas_catalog/published_data_extraction"

## pkgs
library(tidyverse) # tidy code and data
library(readxl) # reading excel files
library(openxlsx) # writing excel files

create_folder <- function(folder) system(paste0("mkdir -p ", folder))

# data path
dat_path <- "data-to-enter"
create_folder(dat_path)

git_clone_jc <- function()
{
	if (!file.exists("epigenetics-journal-club")) {
		message("Cloning the 'epigenetics-journal-club' GitHub repo, this may take some time.")
		system("git clone https://github.com/MRCIEU/epigenetics-journal-club.git")
	}
}

# jc data - needs to be pulled from github
git_pull_jc <- function()
{
	cur_dir <- getwd()
	git_clone_jc()
	setwd("epigenetics-journal-club")
	system("git pull origin main")
	setwd(cur_dir)
}
git_pull_jc()
jc_path <- "epigenetics-journal-club/data/papers.csv"
jc_papers <- read_csv(jc_path, guess_max = 1e6)

# ewas atlas
ea_path <- file.path(dat_path, "ewas_atlas")
create_folder(dat_path)

# download directly from ewas atlas site --> may take a couple of tries
studies_status <- download.file(url = "ftp://download.big.ac.cn/ewas/EWAS_Atlas_studies.tsv", 
								destfile = file.path(ea_path, "studies.tsv"),
								method = "wget")

cohort_status <- download.file(url = "ftp://download.big.ac.cn/ewas/EWAS_Atlas_cohorts.tsv", 
							   destfile = file.path(ea_path, "cohorts.tsv"),
							   method = "wget")

# checking for zero exit status -- if not there has been an error in the download
stopifnot(cohort_status == 0 && studies_status == 0)

ea_files <- c("studies.tsv", "cohorts.tsv")
ea_dat <- lapply(ea_files, function(eaf) {
	# read.delim(file.path(ea_path,eaf), stringsAsFactors=F)
	read_tsv(file.path(ea_path,eaf), guess_max=1e6)
})
ea_dat <- left_join(ea_dat[[1]], ea_dat[[2]])

# read in list of papers already checked
checked_data <- read_xlsx(file.path(dat_path, "master-extraction-list.xlsx"))
checked_data$date <- as.Date(checked_data$date)

# --------------------------------------------
# extract data
# --------------------------------------------
jc_papers_clean <- jc_papers %>%
	dplyr::filter(`EWAS catalog` == "Yes") %>%
	mutate(Date = as.Date(as.character(Date), format = "%Y%m%d")) %>%
	rename(PMID = `Paper ID`) %>%
	dplyr::filter(!PMID %in% as.character(checked_data$pmid)) %>%
	dplyr::select(PMID, Date, Title)

ea_pmid <- ea_dat %>%
	dplyr::filter(sample_size > 99 & platform != "27k") %>%
	mutate(PMID = as.character(PMID)) %>%
	dplyr::select(PMID) %>%
	dplyr::filter(!PMID %in% as.character(checked_data$pmid)) %>%
	dplyr::filter(!PMID %in% jc_papers_clean$PMID) %>%
	distinct()

ea_out <- ea_pmid %>%
	mutate(Date = NA, Title = "ewas_atlas")

out_tab <- bind_rows(jc_papers_clean, ea_out)

check_duplicated_entries <- function(out_tab) 
{
	### check for duplicated pmids and write them out
	### to inspect later

	dup_pmid <- out_tab$PMID[duplicated(out_tab$PMID)]
	if (length(dup_pmid) == 0) {
		message("No duplicated entries, huzzah!")
	} else {
		message("There were ", length(dup_pmid), " duplicated entries")
		dup_file <- "duplicated_pmid_data.csv"
		message("Writing out duplicated data as ", dup_file)
		dup_out <- out_tab %>%
			dplyr::filter(PMID %in% dup_pmid)
		write.csv(dup_out, file = dup_file, 
				  row.names = F, quote = F)
	}
}

check_duplicated_entries(out_tab)
# An entry has the wrong PMID and isn't for the catalog
# out_tab <- out_tab %>%
# 	dplyr::filter(!grepl("Social and physical environments", Title))
# openxlsx::write.xlsx(l, file = "inst/extdata/datasets.xlsx")

# Need to fix medrxiv PMIDs!!
# out_tab <- out_tab %>%
# 	dplyr::filter(!(PMID == "33867313" & Date == "2021-05-10"))

# delete old file 
old_file <- grep("ewas-catalog-data-to-enter-", list.files(dat_path), value = T)
if (length(old_file) > 0) system(paste("rm", file.path(dat_path, old_file)))

today <- Sys.Date()
ext_date <- today ## Extraction date -- change if not today - keep in format "YYYY-mm-dd"
out_file <- paste0("ewas-catalog-data-to-enter-", ext_date, ".xlsx")

openxlsx::write.xlsx(out_tab, file = file.path(dat_path, out_file))

