# ----------------------------------------
# ewas script
# ----------------------------------------

pkgs <- c("tidyverse", "ewaff")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")
source("scripts/useful_functions.R")

read_filepaths("filepaths.sh")

args <- commandArgs(trailingOnly = TRUE)
cohort <- args[1]
extra_cohort_info <- args[2] # for alspac this would be the timepoint and for geo the geo accession
split <- as.numeric(args[3])
n_splits <- as.numeric(args[4])
custom_phens_list <- args[5]

cohort_data_path <- file.path(cohort, extra_cohort_info)

meth_file <- file.path("data", cohort_data_path, "cleaned_meth_data.RData")

meth <- new_load(meth_file)
###
### These files should be renamed and the FOM data should now be put in
### a directory called "FOM"
###
### The GEO files need to be re-organised so that each of the 
### cohorts from GEO is written out in their own directories
###
pheno_file <- file.path("data", cohort_data_path, "cleaned_phenotype_data.txt")
pheno_dat <- read_tsv(pheno_file)

pheno_meta_file <- file.path("data", cohort_data_path, "phenotype_metadata.txt")
pheno_meta <- read_tsv(pheno_meta_file)
pheno_meta$Results_file <- paste0(cohort, "_", extra_cohort_info, "_", 1:nrow(pheno_meta), ".csv")

if (!is.na(custom_phens_list)) {
    phens <- readLines(custom_phens_list)
    pheno_meta <- pheno_meta %>%
        dplyr::filter(phen %in% phens)
}

splits <- round(seq(1, nrow(pheno_meta), length.out = n_splits+1))
if (max(splits) != nrow(pheno_meta)) {
    splits[length(splits)] <- nrow(pheno_meta)
}

split1 <- splits[split]
split2 <- splits[split+1] - 1
if (split2 == nrow(pheno_meta) - 1) {
    split2 <- nrow(pheno_meta)
}

pheno_meta <- pheno_meta[split1:split2, ]

traits <- pheno_meta$phen
pmid <- ifelse(any(grepl("pmid", colnames(pheno_meta))), pheno_meta$pmid, NA)
pmid <- unique(pmid)
samples <- grep("sample_name", colnames(pheno_dat), value = T, ignore.case = T)
devtools::load_all("~/repos/usefunc")

# altering the names to prevent an error in the EWAS 
# colnames(pheno_dat)[grep("^\\d|^_", colnames(pheno_dat))] <- paste0("X", colnames(pheno_dat)[grep("^\\d|^_", colnames(pheno_dat))])
# pheno_meta$phen[grep("^\\d|^_", pheno_meta$phen)] <- paste0("X", pheno_meta$phen[grep("^\\d|^_", pheno_meta$phen)])


## CHANGE THIS --> ONLY WORKS FOR THIS ANALYSIS!
pc_covs <- grep("pc[0-9]*", colnames(pheno_dat), 
                value = TRUE, ignore.case = TRUE)
other_covs <- grep("^age$", colnames(pheno_dat), 
                   value = TRUE, ignore.case = TRUE)
if (tolower(traits) %in% tolower(other_covs)) {
    other_covs <- other_covs[!tolower(other_covs) %in% tolower(traits)]
}
covs <- c(pc_covs, other_covs)
n_cov <- length(covs)

prep_pheno_data <- function(phen, data_path, samples, covs)
{
    # read in svs  
    svs <- read_tsv(file.path("data", data_path, "svs", paste0(phen, ".txt")))

    # Prepare phenotype data
    temp_phen <- pheno_dat %>%
        dplyr::select(one_of(samples), one_of(phen), one_of(covs)) %>%
        left_join(svs) %>%
        na.omit(.)

    # If trait starts with number then change it
    if (grepl("^\\d|^_", phen)) {
        colnames(temp_phen)[colnames(temp_phen) == phen] <- paste0("X", phen)
    }
    return(temp_phen)
}

run_ewas <- function(model, phen, temp_meth, temp_phen, failed_path, res_file)
{
    # Run EWAS using ewaff
    obj <- tryCatch({
        ewaff.sites(model, variable.of.interest = phen,
                           methylation = temp_meth, data = temp_phen, method = "glm", 
                           generate.confounders = NULL, family = "gaussian")
    }, error = function(e) {
        usr_m <- paste0("Error in EWAS of ", phen)
        err_msg(e, r_msg = TRUE, user_msg = usr_m, to_return = phen)
    })
    # free up some space
    rm(temp_meth)

    if (length(obj) == 1) {
        write.table(obj, file = file.path(failed_path, "failed_ewas.txt"), 
                    col.names = F, row.names = F, quote = F, sep = "\n", append = T)
        return(NULL)
    }
    res <- obj$table %>%
        rownames_to_column(var = "probeID") %>%
        dplyr::select(probeID, estimate, se, p.value) %>%
        mutate(Details = NA)

    write.table(res, file = res_file, sep = "\t", col.names = T, row.names = F, quote = F)

    print(paste0("EWAS for ", phen, " saved"))
    return("Run")
}

run_all_ewas_steps <- function(meta_dat, pheno_dat, meth_dat, data_path, out_path, failed_path) 
{
    # get phenotype of interest
    phen <- meta_dat$phen
    res_file <- paste0(out_path, phen, ".txt")
    # if (file.exists(res_file)) return(NULL)

    # prep pheno data
    temp_phen <- prep_pheno_data(phen, data_path, samples, covs)

    # If trait starts with number then change it
    if (grepl("^\\d|^_", phen)) {
        phen <- paste0("X", phen)
    }

    sv_nam <- grep("sv[0-9]", colnames(temp_phen), value = T)

    all_covs <- c(covs, sv_nam)

    # Match meth to Pheno
    temp_meth <- meth_dat[, na.omit(match(temp_phen[[samples]], colnames(meth_dat)))]
    temp_phen <- temp_phen[match(colnames(temp_meth), temp_phen[[samples]]), ]

    if (!all(temp_phen[[samples]] == colnames(temp_meth))) stop("phenotype and DNAm data not matched.")

    model <- as.formula(paste0("methylation ~ ", paste(c(addq(phen), all_covs), collapse = " + ")))

    array <- ifelse(nrow(temp_meth) > 5e5, "Illumina MethylationEPIC", "Illumina HumanMethylation450")

    ewas_run <- run_ewas(model, phen, temp_meth, temp_phen, failed_path, res_file)

    if (is.null(ewas_run)) return(NULL)

    # extract meta data for catalog and output that!
    meta_dat$N <- nrow(temp_phen)
    meta_dat$Methylation_Array <- array
    meta_dat$full_stats_file <- res_file
    return(meta_dat)
}

out_dir <- file.path("results", cohort, "raw", extra_cohort_info, "full_stats/")
failed_dir <- file.path("results", cohort, "raw", extra_cohort_info)
if (!file.exists(out_dir)) make_dir(out_dir)

x=1
meta_out <- map_dfr(1:nrow(pheno_meta), function(x) {
    df <- pheno_meta[x, ]
    df_out <- run_all_ewas_steps(meta_dat = df, 
                                 pheno_dat = pheno_dat,
                                 meth_dat = meth, 
                                 data_path = cohort_data_path,  
                                 out_path = out_dir, 
                                 failed_path = failed_dir)
    return(df_out)
})

meta_out_nam <- file.path("results", cohort, "raw", extra_cohort_info, paste0("catalog_meta_data", split, ".txt"))
write.table(meta_out, file = meta_out_nam,
            quote = F, row.names = F, col.names = T, sep = "\t")
