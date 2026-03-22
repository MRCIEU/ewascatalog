# -------------------------------------------------------
# Extracting ALSPAC data
# -------------------------------------------------------

# requirements for this script to work:
# 1. need IDs for people in ARIES
# 2. need Tom's version of alspac package: github.com/thomasbattram/alspac
#    (made pull request with main package, but not accepted...)
# 3. access to alspac data (duhhh)

pkgs <- c("alspac", "tidyverse", "haven", "readxl", "varhandle")
lapply(pkgs, require, character.only = T)

# need to go to the correct directory first!
source("scripts/read_filepaths.R")
source("scripts/useful_functions.R")

read_filepaths("filepaths.sh")
output_path <- paste0(local_rdsf_dir, "data/alspac/", timepoints)

message("alspac data directory is: ", alspac_data_dir)
message("the ouput path is: ", output_path)
message("the ARIES ID file is: ", aries_ids_file)
message("timepoints are: ", timepoints)
# setwd(wd)
stopifnot(file.exists(output_path))
stopifnot(file.exists(alspac_data_dir))
id_file_path <- paste0(local_rdsf_dir, "data/alspac/", aries_ids_file)
stopifnot(file.exists(id_file_path))

setDataDir(alspac_data_dir)

# devtools::load_all("")
# devtools::load_all("") # not sure if works!!!

data(current)
data(useful)

# -------------------------------------------------------
# RUN THIS TO UPDATE THE DICTIONARIES
# -------------------------------------------------------
# current <- createDictionary("Current", name="current")
# useful <- createDictionary("Useful_data", name="useful")

# -------------------------------------------------------
# Filter out data not present enough in ARIES
# -------------------------------------------------------

# Read in the ARIES IDs and extract ones from timepoint of interest
IDs <- read_tsv(id_file_path)
IDs <- dplyr::filter(IDs, time_point == timepoints)
str(IDs)

# ------------------------------------------------------------------------------------
# Extract data 
# ------------------------------------------------------------------------------------

if ("FOM" %in% timepoints) {
	tim_dat <- "FOM1"
	vars_of_interest <- grep(tim_dat, current$lab, value = T)
}

new_current <- current %>%
	dplyr::filter(lab %in% vars_of_interest)

# paths of interest
# PoI <- c()

# extraction
result <- extractVars(new_current)

# ------------------------------------------------------------------------------------
# Initial look at data 
# ------------------------------------------------------------------------------------
## finding the age of participants at each questionnaire

mult_cols <- grep("mult", colnames(result), value = T)

attributes(result[[mult_cols]])
# looks like 1 = duplicated so remove them!
res <- result %>%
	dplyr::filter(aln %in% IDs$ALN) %>%
	dplyr::filter(!! mult_cols != 1)

# check for aln and qlet columns.
grep("aln|qlet", colnames(res), value = T)
# Change if more than just aln, alnqlet, qlet
dim(res)
dim(new_current)
# delete extra columns minus the aln, qlet and alnqlet columns
col_rm <- colnames(res)[!colnames(res) %in% new_current$name]
col_rm <- col_rm[!col_rm %in% c("aln", "qlet", "alnqlet")]
res <- res[,!colnames(res) %in% col_rm]
qlet_cols <- grep("qlet", colnames(res), value = T)

# function to get all the descriptive names of the alspac variables
get_full_names <- function(input) {
	out <- map_chr(seq_along(input), function(x) {
		if (is.null(attributes(input[[x]]))) return(colnames(input[x]))
		return(attr(input[[x]], "label"))
	})
	return(out)
}

nams <- get_full_names(res)

all_labels <- map_df(seq_along(res), function(x) {
	if (is.null(attributes(res[[x]]))) return(NULL)
	labels <- attr(res[[x]], "labels")
	out <- data.frame(lab = names(labels), value = labels)
	return(out)
})


# ------------------------------------------------------------------------------------
# Start cleaning data
# ------------------------------------------------------------------------------------

# making the data factors makes it easy to extract extra data labels!
fact_res <- as_factor(res)
# find the variables that signify missing or withdrawn consent data
unique(all_labels$lab)

na_vars <- unique(c(grep("missing|consent", all_labels$lab, ignore.case = TRUE, value = TRUE),
				  "Mother of trip/quad", 
				  "Did not attend clinic", 
				  "Unresolvable", 
				  "Value outside possibel range (negative value)", 
				  "Insufficient sample for analysis", 
				  grep("Out of detectable range", all_labels$lab, value = TRUE), 
				  "Outside of standard calibration curve (<780 ng/ml or >100,000 ng/ml)", 
				  "Insufficient sample for assay", 
				  grep("detection limit of test", all_labels$lab, value = TRUE)
				  ))


fact_res[] <- lapply(seq_along(fact_res), function(x) {
	var <- fact_res[[x]] 
	out <- mapvalues(var, from=na_vars, to=rep(NA, length(na_vars)))
	return(out)
})

cat_vars <- map_chr(seq_along(fact_res), function(x) {
	phen_levels <- levels(fact_res[[x]])
	if (is.null(phen_levels)) return("NULL")
	# remove missing and consent withdrawn
	phen_levels <- phen_levels[-grep("missing|consent", phen_levels, ignore.case = TRUE)]
	if (length(phen_levels) < 20 & length(phen_levels) > 2) {
		return(colnames(fact_res[x]))
	} else {
		return("NULL")
	}
})
cat_vars <- cat_vars[cat_vars != "NULL"]
cat_var_full_names <- get_full_names(res[, cat_vars])
# no categorical variables!!! --> WOOP WOOP!

# --------------------------------------------------------------
# remove phenotypes with too much missing data
# --------------------------------------------------------------
missing_dat <- map_df(seq_along(fact_res), function(x) {
	out <- data.frame(phen = colnames(fact_res[x]), na_count = sum(is.na(fact_res[[x]])))
	return(out)
})
sum(missing_dat$na_count > nrow(res)/2) # 18 phenotypes have over 50% missing data
to_rm <- missing_dat[missing_dat$na_count > nrow(res)/2, "phen"]
res2 <- fact_res %>%
	dplyr::select(-one_of(to_rm))

# select only variables left
res2[] <- lapply(seq_along(res2), function(x) {
	print(x)
	col_nam <- colnames(res2)[x]
	var <- res2[[x]]
	if (col_nam %in% c("aln", qlet_cols)) return(var)
	label <- attributes(var)$label
	out <- unfactor(var)
	attributes(out)$label <- label
	return(out)
})
dim(res2)

# ------------------------------------------------------------------------------------
# Sorting binary vals
# ------------------------------------------------------------------------------------

bin_vars <- map_lgl(res2, is.binary)

res_bin <- res2[, bin_vars]
res2 <- res2[, !(colnames(res2) %in% colnames(res_bin))]

# removing any extra labels! 
res2[] <- lapply(seq_along(res2), function(x) {
	col_nam <- colnames(res2)[x]
	var <- res2[[x]]
	print(x)
	if (col_nam %in% c("aln", qlet_cols)) return(var)
	label <- attributes(var)$label
	out <- as.numeric(var) # makes any non-numeric values NAs
	attributes(out)$label <- label
	return(out)
})

# Removal of categories where there are <100 values
missing <- sapply(res2, function(x) {sum(is.na(x))})
names(missing)
vars_rm <- missing[missing > (nrow(res2) / 2)]
length(vars_rm) # 9 variables removed due to lack of people
res3 <- res2 %>%
	dplyr::select(-one_of(names(vars_rm)))
dim(res3)

uniq_vals <- sapply(res_bin, function(x) length(unique(x[!is.na(x)])))
# remove any without 2 unique values
to_rm <- names(uniq_vals)[uniq_vals != 2]
res_bin <- res_bin[, !(colnames(res_bin) %in% to_rm)]

# remove binary variables with too few cases
# -- removing if less than 10% cases or controls
few_cases <- apply(res_bin, 2, function(x) {sum(unique(x)[1] == x, na.rm = T) < (nrow(res_bin) / 10)})
few_controls <- apply(res_bin, 2, function(x) {sum(unique(x)[2] == x, na.rm = T) < (nrow(res_bin) / 10)})

cc_var_rm <- unique(c(names(which(few_controls)), names(which(few_cases))))
cc_var_rm <- cc_var_rm[!cc_var_rm %in% qlet_cols]
length(cc_var_rm) # 51
res_bin <- dplyr::select(res_bin, -one_of(cc_var_rm))

# remove binary variables with too much missing
missing <- sapply(res_bin, function(x) {sum(is.na(x))})
names(missing)
vars_rm <- missing[missing > (nrow(res_bin)/2)]
length(vars_rm) # 0 variables removed due to lack of people

res3 <- cbind(res3, res_bin)
dim(res3)
# ------------------------------------------------------------------------------------
# Finishing tidying data + saving it all
# ------------------------------------------------------------------------------------

# Swap the labels and the alspac names
res3_nam <- get_full_names(res3)
res4 <- map_dfc(seq_along(res3), function(x) {
	var <- res3[[x]]
	attributes(var)$alspac_name <- colnames(res3[x])
	return(var)
})
colnames(res4) <- res3_nam

# Rename the headings to remove all the unusable characters for GCTA
colnames(res4) <- gsub("\\%", "percent", colnames(res4))
colnames(res4) <- gsub("[[:punct:]]", "_", colnames(res4))
colnames(res4) <- gsub(" ", "_", trimws(colnames(res4)))

# Extract all the meta data! 
phen_list <- map_df(seq_along(res4), function(x) {
	if (colnames(res4[x]) %in% c(qlet_cols, "aln")) return(NULL)
	out <- data.frame(
		phen = colnames(res4[x]),
		binary = is.binary(res4[[x]]),
		n = sum(!is.na(res4[[x]])),
		alspac_name = attributes(res4[[x]])$alspac_name,
		unedited_label = attributes(res4[[x]])$label
		) %>%
		mutate(obj = new_current[new_current$name == alspac_name, "obj"])
	return(out)
})

# 2 differences: cm_2 and cm2 + lipids and lipds

phen_list$include <- NA
# write out this data and decide on what to keep then save it!
phen_file_nam <- file.path(output_path, "phenotype_metadata.txt")
# here write out the table, put it into an excel spreadsheet
# and manually choose which traits to keep after discussion
# make the decision by changing the include column to "Y" or "N"
write.table(phen_list, phen_file_nam, 
			row.names = F, col.names = T, quote = F, sep = "\t")
new_phen_file_nam <- gsub(".txt", ".xlsx", phen_file_nam)
if (!file.exists(new_phen_file_nam)) {
	stop("Write out and discuss which traits to keep!")
} else if (file.exists(new_phen_file_nam)) {
	new_phen_list <- read_xlsx(new_phen_file_nam) %>%
		dplyr::filter(include == "Y")
	phens_removed <- phen_list %>%
		dplyr::filter(!phen %in% new_phen_list$phen) %>%
		pull(phen)
	if (length(phens_removed) == 0) warning("You'd expect to throw out some phenotypes!")
	write.table(phens_removed, file = file.path(output_path, "removed_phens.txt"), 
				row.names = F, col.names = F, quote = F, sep = "\t")
}

# overwrite old phen list file
write.table(new_phen_list, file = phen_file_nam, 
			row.names = F, col.names = T, quote = F, sep = "\t")

# remove bad phenotypes from actual results
res4 <- res4 %>%
	dplyr::select(aln, qlet, alnqlet, one_of(new_phen_list$phen))

meta_data_out %>%
	dplyr::filter(grepl("insulin", unedited_label, ignore.case = T)) %>%
	dplyr::select(unedited_label, obj)

res_file_nam <- file.path(output_path, "phenotype_data.txt")
write.table(res4, file = res_file_nam, quote = F, col.names = T, row.names = F, sep = "\t")

if (timepoints == "F7" | timepoints == "15up") {
	age_g <- "Children"
} else if (timepoints == "cord") {
	age_g <- "Infants"
} else {
	age_g <- "Adults"
}
if (timepoints == "FOM" | timepoints == "antenatal") {
	sex <- "Females"
} else if (timepoints == "FOF") {
	sex <- "Males"
} else {
	sex <- "Both"
}
# Write studies file
studies <- tibble(Author = "Battram T", 
                  Cohorts_or_consortium = "ARIES", 
                  PMID = NA, 
                  Date = Sys.Date(),
                  Trait = new_phen_list$unedited_label, 
                  EFO = NA,
                  Trait_units = NA, 
                  dnam_in_model = "Outcome",
                  dnam_units = "Beta Values", 
                  Analysis = NA, 
                  Source = NA, 
                  Covariates = "Batch effects, cell composition (reference free), ancestry (genomic PCs)", 
                  Methylation_Array = "Illumina HumanMethylation450", 
                  Tissue = "Whole blood", 
                  Further_Details = NA, 
                  N = NA, 
                  N_Cohorts = 1, 
                  Age_group = age_g, 
                  Sex = sex, 
                  Ethnicity = "European", 
                  Results_file = NA
                 )

# making temp directory for excel files to be moved over to the 
# rdsf because it is so bloody slow to write and edit in rdsf
temp_dir <- "temp"
make_dir(temp_dir)

studies <- studies %>%
	arrange(Trait) %>%
	mutate(unedited_label = Trait)

openxlsx::write.xlsx(studies, file = file.path(temp_dir, "catalog_meta_data.xlsx"))

# Open, alter traits, add EFO terms, add to analysis and further details too
system(paste0("open ", file.path(temp_dir, "catalog_meta_data.xlsx")))

# Read the data back in and bind it to the meta-data
studies <- readxl::read_xlsx(file.path(temp_dir, "catalog_meta_data.xlsx"))

phen_meta <- new_phen_list %>%
	arrange(unedited_label)

meta_data_out <- left_join(phen_meta, studies)

## make some manual changes if needed
# traits_to_rm <- c("Insulin u/ml, fasting FOM1", "Trunk Left Bone Mass (g)", 
# 				  "Trunk Left Fat Mass (g)", "Trunk Left Lean Mass (g)")
# meta_data_out <- meta_data_out %>%
# 	dplyr::filter(!Trait %in% traits_to_rm)

# write.table(traits_to_rm, file = file.path(output_path, "removed_phens.txt"), 
# 			row.names = F, col.names = F, quote = F, sep = "\t", append=T)

# overwrite old phen list file
write.table(meta_data_out, file = phen_file_nam, 
			row.names = F, col.names = T, quote = F, sep = "\t")

# Set new password each time
PASSWORD <- alsp_password ## REMEMBER THIS!

zip(gsub(".txt", ".zip", res_file_nam), 
    files = res_file_nam, 
    flags = paste("--password", PASSWORD))

system(paste0("rm ", res_file_nam))

# FIN!