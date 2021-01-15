# ---------------------------------------------
# checking geo methylation data and make SVs
# ---------------------------------------------

## pkgs
library(tidyverse) # tidy code and data
library(sva) # surrogate variable analyses
library(SmartSVA) # faster SVA
library(matrixStats) # functions to create models for SVA

source("scripts/useful_functions.R")

# ---------------------------------------------
# load in data! 
# ---------------------------------------------

geo_path <- "data/geo"
geo_accessions <- readLines(file.path(geo_path, "geo_accession.txt"))

# ---------------------------------------------
# loop over datasets
# ---------------------------------------------

# to check
# 1. column names match the sample_name column in the pheno data
# 2. data is there

check_cols_and_rows <- function(meth_dat, phen_dat) 
{
	## Check column names of meth_dat are sample names in pheno data
	cols <- colnames(meth_dat)
	if (!any(cols %in% phen_dat$sample_name)) stop("methylation sample names not in phenotype sample name column")
	message("columns are good")
	## Check rownames of meth_dat are CpG site names
	rows <- rownames(meth_dat)	
	if (!all(grepl("^c", rows))) stop("rownames are not cpg sites")
	message("rows are good")
}

check_betas <- function(meth_dat, n) {
	b1_10 <- meth_dat[sample(1:nrow(meth_dat), n), ]
	test <- map_lgl(1:nrow(b1_10), function(x) {
		cpg <- b1_10[x, ]
		cpg <- cpg[!is.na(cpg)]
		out <- any(cpg > 1 | cpg < 0)
		return(out)
	})
	if (any(test == "bad")) {
		stop("sort out betas")
	} else {
		message("All goood! Going ahead with generating SVs now!")
	}
}

read_meth_data <- function(meth_file)
{
	ga_path <- file.path(geo_path, ga)
	meth_file_nam <- paste0(tolower(ga), ".rda")
	meth_file <- file.path(ga_path, meth_file_nam)
	old_meth_file <- meth_file
	if (!file.exists(meth_file)) {
		meth_file <- file.path(ga_path, "cleaned_meth_data.RData")	
	} 
	if (!file.exists(meth_file)) {
		stop("meth file doesn't exist. Have you moved it from the RDSF space?")
	}
	meth <- new_load(meth_file)	
	## remove series_matrix from rownames if present
	meth <- meth[!grepl("series_matrix", rownames(meth)), ]
	return(meth)
}

rows <- rownames(meth)
x <- rows[!grepl("cg", rows)]
new_meth <- meth[rows %in% x, ]
i=x[1]
lapply(x, function(i) {
	new_meth <- meth[rows %in% i, ]
	check_betas(new_meth, n=nrow(new_meth))
})
check_betas(new_meth, n=nrow(new_meth))

ga=geo_accessions[1] # SHOULD WORK!
ga <- "GSE120878"
# check colnames and rownames
lapply(geo_accessions, function(ga) {
	## load in data
	print(ga)
	ga_path <- file.path(geo_path, ga)
	# methylation data
	meth <- read_meth_data(ga)
	# pheno data
	pheno_dat <- read_tsv(file.path(ga_path, "cleaned_phenotype_data.txt"))
	meta_dat <- read_tsv(file.path(ga_path, "phenotype_metadata.txt"))

	# check colnames and rows of methylation data
	meth <- meth[grep(sites, rownames(meth)), ]
	check_cols_and_rows(meth, pheno_dat)
	# check methylation betas 
	check_betas(meth, n = 100)
	meth <- as.matrix(meth)
	mdata <- impute_matrix(meth)
	save(meth, file = file.path(ga_path, "cleaned_meth_data.RData"))

	sv_out_dir <- paste0(ga_path, "/svs/")
	if (!file.exists(sv_out_dir)) make_dir(sv_out_dir)
	# make SVs
	lapply(meta_dat$phen, function(phen) {
		pheno_dat[[phen]] <- type.convert(pheno_dat[[phen]])
		generate_svs(trait = phen, 
					 phen_data = pheno_dat, 
					 meth_data = mdata, 
					 covariates = "", 
					 nsv = 20, 
					 out_path = sv_out_dir, 
					 samples = "sample_name")
	})
	# remove old methylation data! 
	# cmd <- paste("rm", old_meth_file)
	# system(cmd)
})

# geo_accessions <- readLines(file.path(geo_path, "geo_accession.txt"))


# check which ones failed
lapply(geo_accessions, function(ga) {
	sv_out_dir <- paste0(file.path(geo_path, ga), "/svs/")
	if (file.exists(paste0(sv_out_dir, "sv_fails.txt"))) {
		message("making SVs failed in the ", ga, "dataset")
	}
})

# ---------------------------------------------------
# cleaning the epic array datasets! 
# ---------------------------------------------------

phenofile <- "data/geo/ewas-cat-cr02.rdata"
load(phenofile)

epic_array <- c("GSE112596", "GSE107080", "GSE118144")
# ---------------------------------------------------
# cleaning first epic array dataset
# ---------------------------------------------------
ga <- epic_array[1]
all_info <- geo[[ga]]
str(all_info)
ga_path <- file.path(geo_path, ga)
# pheno data
pheno_file <- file.path(ga_path, "cleaned_phenotype_data.txt")
pheno_dat <- read_tsv(pheno_file)
# methylation data
meth_file_nam <- paste0(tolower(ga), ".rda")
meth_file <- file.path(ga_path, meth_file_nam)
old_meth <- new_load(meth_file)
meth <- old_meth

colnames(meth)

# colnames look very similar to all_info$title...
cols <- gsub("-", ".", all_info$title)
colnames(meth)

# cpgs are listed under "ID" column --> change to rownames
rownames(meth) <- meth$ID
meth <- meth[, colnames(meth) != "ID"] 
meth <- meth[, cols] # This removed a load of columns, but these were all "p < x" so clearly not beta values

# change the colnames out for the geo accessions! 
index <- match(cols, colnames(meth))
meth <- meth[, index]
all(colnames(meth) == cols)
colnames(meth) <- all_info$geo_accession

# now just take out the unnecessary data
meth <- meth[, colnames(meth) %in% pheno_dat[["sample_name"]]]

# save the old version of the meth data
old_dir <- file.path(ga_path, "old_meth_data/")
if (!file.exists(old_dir)) make_dir(old_dir)
save(old_meth, file = paste0(old_dir, meth_file_nam))
# save the new data, ready for an EWAS! 
save(meth, file = meth_file)

# ---------------------------------------------------
# cleaning second epic array dataset
# ---------------------------------------------------
ga <- epic_array[2]
all_info <- geo[[ga]]
str(all_info)
ga_path <- file.path(geo_path, ga)
# pheno data
pheno_file <- file.path(ga_path, "cleaned_phenotype_data.txt")
pheno_dat <- read_tsv(pheno_file)
# methylation data
meth_file_nam <- paste0(tolower(ga), ".rda")
meth_file <- file.path(ga_path, meth_file_nam)
old_meth <- new_load(meth_file)
meth <- old_meth

# colnames look similar to all_info$description.2
cols <- gsub(" ", ".", all_info$description.2)
colnames(meth)

# cpgs are listed under "ID" column --> change to rownames
rownames(meth) <- meth$ID_REF
meth <- meth[, colnames(meth) != "ID_REF"] 
meth <- meth[, cols] # This removed a load of columns, but these were all "p < x" so clearly not beta values

# change the colnames out for the geo accessions! 
index <- match(cols, colnames(meth))
meth <- meth[, index]
all(colnames(meth) == cols)
colnames(meth) <- all_info$geo_accession

# now just take out the unnecessary data (from previous cleaning, see above!)
meth <- meth[, colnames(meth) %in% pheno_dat[["sample_name"]]]

# save the old version of the meth data
old_dir <- file.path(ga_path, "old_meth_data/")
if (!file.exists(old_dir)) make_dir(old_dir)
save(old_meth, file = paste0(old_dir, meth_file_nam))
# save the new data, ready for an EWAS! 
save(meth, file = meth_file)


# ---------------------------------------------------
# cleaning third epic array dataset
# ---------------------------------------------------
ga <- epic_array[3]
all_info <- geo[[ga]]
str(all_info)
ga_path <- file.path(geo_path, ga)
# pheno data
pheno_file <- file.path(ga_path, "cleaned_phenotype_data.txt")
pheno_dat <- read_tsv(pheno_file)
# methylation data
meth_file_nam <- paste0(tolower(ga), ".rda")
meth_file <- file.path(ga_path, meth_file_nam)
old_meth <- new_load(meth_file)
meth <- old_meth

# colnames look similar to all_info$title
cols <- paste(gsub(":.*", "", all_info$title), "AVG_Beta", sep = ".")
colnames(meth)

# cpgs are listed under "ID" column --> change to rownames
rownames(meth) <- meth$TargetID
meth <- meth[, colnames(meth) != "TargetID"] 
meth <- meth[, cols] # This removed a load of columns, but these were all "p < x" so clearly not beta values

# change the colnames out for the geo accessions! 
index <- match(cols, colnames(meth))
meth <- meth[, index]
all(colnames(meth) == cols)
colnames(meth) <- all_info$geo_accession

# now just take out the unnecessary data (from previous cleaning, see above!)
meth <- meth[, colnames(meth) %in% pheno_dat[["sample_name"]]]

# save the old version of the meth data
old_dir <- file.path(ga_path, "old_meth_data/")
if (!file.exists(old_dir)) make_dir(old_dir)
save(old_meth, file = paste0(old_dir, meth_file_nam))
# save the new data, ready for an EWAS! 
save(meth, file = meth_file)

