# -------------------------------------------------
# Sorting geo phenotypes for EWAS
# -------------------------------------------------

## script takes geo phenotype data extracted using the geograbi package
## extracts the phenotypes of interest and sorts the data ready for EWAS

## pkgs
library(tidyverse) # tidy data and code
library(readxl) # reading in excel spreadsheets

## some functions needed for analyses
source("scripts/read_filepaths.R")
source("scripts/useful_functions.R")

## all filepaths needed
read_filepaths("filepaths.sh")

## extra functions that may be needed
devtools::load_all("~/repos/usefunc")

# -------------------------------------------------
# read in data
# -------------------------------------------------
data_folder <- "data/geo"

all_df_files <- c(
	my_gses = "get-ewas-cat-geo-data-01-my.gses.rds",
	ecat_gses = "get-ewas-cat-geo-data-02-ecat.gses.rds",
	ecat_data = "get-ewas-cat-geo-data-03-ecat.data.rds",
	exception_data = "get-ewas-cat-geo-data-04-exception.data.rds",
	ecat = "get-ewas-cat-geo-data-05-ecats.rds",
	ecat_for_print = "get-ewas-cat-geo-data-06-ecats.for.print.rds"
)

all_df <- lapply(all_df_files, function(file) {
	readRDS(file.path(data_folder, file)) %>%
        as_tibble()
})

lapply(all_df, class)
lapply(all_df, dim)

## not sure any of the above files are useful... ignoring for now!

chrs_file <- "get-ewas-cat-geo-data-02-chrs.rds"
chrs <- readRDS(file.path(data_folder, chrs_file))
head(chrs[[1]])
names(chrs)[1]

# remove matrix part from chrs names
names(chrs) <- gsub("_series_matrix.txt.gz", "", names(chrs))

## NB. The characters file currently does not have IDs that are 
##     linked to the methylation data BUT for now have checked 
##     the order of phenotypes (rows) is the same as the order of 
##     columns in the corresponding methylation matrix

## 
## OLD FILE WHEN GEOGRABI EXTRACTION WAS DIFFERENT
## 
phenofile <- "data/geo/ewas-cat-cr02.rdata"
load(phenofile)
# phenofile contains
# all.gses:
#   a d.f, looks like all GSEs and some meta data
# my.gses:
#   a d.f, similar to all.gses but it's filtered and has
#   filenames and pubmed_id 
# ecat.gses:
#   a d.f, similar to all.gses, but with a filtered list of GSEs +
#   lots of columns containing potential phenotype info
# ecats:
#   a d.f, similar to ecat.gses, but with fewer GSEs, unsure why
# ecats.for.print:
#   a d.f, similar to ecats, but with slightly different column names
#   unsure of reason for each
# chrs: 
#   a list of d.fs, each element of the list contains phenotype info
#   for a GSE, looks to be same GSEs as in ecat.gses --> USEFUL
# geo:
#   a list of d.fs, each element of the list contains meta data info
#   for a GSE, looks to be same GSEs as in ecat.gses --> USEFUL


# Manually reviewed to see if analysis could be done
# for the catalog
new_geo_asc <- readLines(file.path(data_folder, "new-geo-accession-ids.txt"))
reviewed_data <- read_excel(file.path(data_folder, "ewas-cat-gses-for-review.xlsx"))
str(reviewed_data)
colnames(reviewed_data)
include_col <- grep("include", colnames(reviewed_data), value = TRUE)
renam_var <- c(include = include_col)

effect_cols <- grep("effect.col.name", colnames(reviewed_data), value = T)

pub_dat <- reviewed_data %>%
    rename(!!renam_var) %>%
    dplyr::filter(accession %in% new_geo_asc, 
                  include == 2) %>%
    # removal of variables that haven't got anything in
    dplyr::select(which(!map_lgl(., function(x) {all(x == "NA")}))) %>%
    dplyr::select(accession, pubmed_id, main.effect, samples, include, comment,
                  one_of(effect_cols), 
                  one_of(grep("chr.fld", colnames(reviewed_data), value = T)))

# -------------------------------------------------
# Extract trait for the analysis
# -------------------------------------------------

# traits for EWAS
pub_dat$main.effect

nrow(pub_dat) # 4 datasets selected (2020-10-13)

## 
## OLD EXTRACTION WHEN GEOGRABI EXTRACTION WAS DIFFERENT
## 
# extract the phenotypes and sample_names
geo_asc <- pub_dat$accession
phen_list <- lapply(geo_asc, function(ga) {
    all_info <- geo[[ga]]
	  pheno <- chrs[[ga]]
    # some files have values as a row rather than a column
    # so this if statement sorts them out
	if (nrow(pheno) == 1) {
        print(ga)
		values <- as.character(pheno[1,])
		phe <- data.frame(values)
		colnames(phe) <- colnames(pheno)[1]
		pheno <- phe
	}
	pheno$sample_name <- rownames(all_info)
	return(pheno)
})
names(phen_list) <- geo_asc



## newer script --
## make directories of geo accession
geo_asc <- pub_dat$accession
lapply(geo_asc, function(ga) {
    make_dir(file.path(data_folder, ga))
})

## function for getting sample names as they're not in chrs data...
get_sample_names <- function(ga)
{
    ## read in meth matrix
    meth_file <- file.path(data_folder, ga, paste0(tolower(ga), ".rda"))
    meth <- new_load(meth_file)
    return(colnames(meth))
}
ga <- geo_asc[1]
phen_list <- lapply(geo_asc, function(ga) {
    pheno <- chrs[[ga]]
    # some files have values as a row rather than a column
    # so this if statement sorts them out
    if (nrow(pheno) == 1) {
        print(ga)
        values <- as.character(pheno[1,])
        phe <- data.frame(values)
        colnames(phe) <- colnames(pheno)[1]
        pheno <- phe
    }
    pheno$sample_name <- get_sample_names(ga)
    ## ADD SAMPLE NAMES HERE!
    return(pheno)
})
names(phen_list) <- geo_asc


# extract phenotype names
phens <- lapply(phen_list, colnames)

effect_phen_dat <- lapply(geo_asc, function(ga) {
    print(ga)
    d <- phen_list[[ga]]
    VoI <- pub_dat %>%
        dplyr::filter(accession == ga) %>%
        dplyr::select(one_of(effect_cols)) %>%
        as.character()
    empty_cols <- which(colnames(d) == "")
    for (i in empty_cols) {
        colnames(d)[i] <- paste0("no_name", i)
    }
    d <- d %>%
        dplyr::select(sample_name, one_of(VoI))
    return(d)
})
names(effect_phen_dat) <- geo_asc

# write out the data so it can be manually sorted
messy_out_list <- list(geo_asc = geo_asc, 
                       effect_phen_dat = effect_phen_dat, 
                       pub_dat = pub_dat)

out_nam <- paste0("data/geo/messy_geo_data_to_sort_", Sys.Date(), ".RData")
save(messy_out_list, file = out_nam)

# go to manual_geo_phenotype_sorting.R
# when done there, load packages and stuff up top and start
# again from here

# continue with data sorting (load in all before data at start of script)
clean_file_nam <- paste0("data/geo/clean_geo_data_to_sort_", Sys.Date(), ".RData")
if (!file.exists(clean_file_nam)) stop("Sort out your data using the manual_geo_phenotype_sorting.R script")
clean_dat <- new_load(clean_file_nam)

geo_asc <- clean_dat$geo_asc
effect_phen_dat <- clean_dat$effect_phen_dat
pub_dat <- clean_dat$pub_dat

# ---------------------------------------
# extract some useful meta data from datasets
# ---------------------------------------

# sort out names + add meta data then write out the results! 
nam="GSE40279"
met_dat <- lapply(names(effect_phen_dat), function(nam) {
    print(nam)
    df <- effect_phen_dat[[nam]]
    pubmid <- pub_dat %>%
        dplyr::filter(accession == nam) %>%
        pull(pubmed_id)
    old_effect_nam <- colnames(df)[colnames(df) != "sample_name"]
    out_dat <- map_dfr(old_effect_nam, function(oen) {
        new_effect_nam <- tolower(gsub("[[:space:]]", "_", oen)) 
        new_effect_nam <- gsub('[[:punct:]]', '_' , new_effect_nam)
        bin <- is.binary(df[[oen]])
        out <- tibble(geo_asc = nam, 
                     pmid = pubmid, 
                     phen = new_effect_nam, 
                     binary = bin, 
                     unedited_label = oen, 
                     n = nrow(df))
        return(out)
    })
    return(out_dat)
})
names(met_dat) <- geo_asc

# for meta-data, the actual name of the trait will
# need to be mannually edited using the review file

generate_studies <- function(meta_dat)
{
    tibble(Author = "Battram T", 
           Cohorts_or_consortium = "GEO", 
           PMID = meta_dat$pmid, 
           Date = Sys.Date(),
           Trait = meta_dat$unedited_label, 
           EFO = NA,
           Trait_units = NA, 
           dnam_in_model = "Outcome",
           dnam_units = "Beta Values", 
           Analysis = paste0("EWAS Catalog re-analysis of GEO data. GEO accession ID is ", meta_dat$geo_asc), 
           Source = NA, 
           Covariates = "Batch effects, cell composition (reference free)", 
           Methylation_Array = "Illumina HumanMethylation450", 
           Tissue = NA, 
           Further_Details = NA, 
           N = meta_dat$n, 
           N_Cohorts = 1, 
           Age_group = NA, 
           Sex = NA, 
           Ethnicity = NA, 
           Results_file = NA
          )
}

# ------------------------------------------------------
# clean data
# ------------------------------------------------------

# set outliers to missing
no_out_phen <- lapply(geo_asc, function(ga) {
    print(ga)
    df <- effect_phen_dat[[ga]]
    # if binary then give it a miss
    met_df <- met_dat[[ga]]
    cols <- colnames(df)
    out_dat <- map_dfc(cols, function(trait) {
        var <- df[[trait]]
        # return variable if sample_name or binary
        if (trait %in% "sample_name") return(var)
        bin_val <- met_df[met_df$unedited_label == trait, "binary"]
        if (bin_val == TRUE) return(var)

        var <- as.numeric(var)
        out <- set_outliers_to_na(var)
        total_vals <- sum(!is.na(out))
        new_na <- sum(is.na(out)) - sum(is.na(var))
        message(new_na, " values set to missing for ", trait)
        message(total_vals, " non missing values remain for ", trait)
        return(out)
    })
    colnames(out_dat) <- cols
    return(out_dat)
})
names(no_out_phen) <- geo_asc
# doesn't seem to be removal of many values!

# check zero values
count_zero <- lapply(geo_asc, function(ga) {
    print(ga)
    df <- no_out_phen[[ga]]
    # if binary then give it a miss
    met_df <- met_dat[[ga]]
    count_zero <- map_dbl(1:nrow(met_df), function(x) {
        bin <- met_df[x, "binary", drop = TRUE]
        if (bin) return(NA)
        col <- met_df[x, "unedited_label", drop = TRUE]
        sum(df[[col]] == 0, na.rm = T)
    })
    names(count_zero) <- met_df$unedited_label
    return(count_zero)
})
# only phenotype with any zeros is total body naevus count,
# which makes total sense! 

fin_dat <- no_out_phen

# ------------------------------------------------------
# write out the data!
# ------------------------------------------------------

# write out cleaned phenotype data and meta data
lapply(geo_asc, function(ga) {
    meta_dat <- met_dat[[ga]]

    # generate studies data and join back to meta-data
    studies <- generate_studies(meta_dat) %>%
        mutate(unedited_label = Trait)
    meta_dat <- meta_dat %>%
        left_join(studies)
    
    # rename variables as appropriate
    pheno_dat <- fin_dat[[ga]] %>%
        rename_at(vars(meta_dat$unedited_label), ~ meta_dat$phen)

    out_path <- file.path("data/geo", ga)

    if (!file.exists(out_path)) make_dir(out_path)

    meta_nam <- file.path(out_path, "phenotype_metadata.txt")
    write.table(meta_dat, file = meta_nam,
                col.names = T, row.names = F, quote = F, sep = "\t")
    
    pheno_nam <- file.path(out_path, "cleaned_phenotype_data.txt")
    write.table(pheno_dat, file = pheno_nam,
                col.names = T, row.names = F, quote = F, sep = "\t")
    return(NULL)
})

# write out geo accession numbers being used
write.table(geo_asc, file = "data/geo/geo_accession.txt", 
            col.names = F, row.names = F, quote = F, sep = "\n")

