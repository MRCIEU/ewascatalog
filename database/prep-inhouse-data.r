# ----------------------------------------------------
# Sort new ewas data for input into catalog
# ----------------------------------------------------

# Script objectives:
#	1  Run checks on study and results data
#	2. Update study data columns so they fit what's in the catalog
#   3. Generate STUDY-ID for each study
#	4. Output data to FILE_DIR/ewas-sum-stats/study-data/STUDY-ID
#	5. Add STUDY-ID to "studies-to-add.txt"
#   6. Remove results files from FILE_DIR/ewas-sum-stats/inhouse-data/
#   7. Write out any failures in prep

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
file_dir <- args[1]
inhouse_dir <- file.path(file_dir, "ewas-sum-stats/inhouse-data")
res_dir <- file.path(inhouse_dir, "results")
out_dir <- file.path(file_dir, "ewas-sum-stats/study-data")
sfile <- "studies.xlsx"
# sfile <- "studies_template_inhouse_test.xlsx"

if (!file.exists(file.path(inhouse_dir, sfile))) {
    stop("studies.xlsx doesn't exist")
}

res_files <- list.files(res_dir)
if (any(duplicated(res_files))) stop("There are duplicated results files, please rename the files!")

studies <- readxl::read_excel(file.path(inhouse_dir, sfile), sheet="data")
cpg_annotations <- data.table::fread(file.path(file_dir, "cpg_annotation.txt"))
# ----------------------------------------------------
# Functions to check data
# ----------------------------------------------------

check_nchar <- function(dat, max_nchars, stud_dat) 
{
    ### check character length of data
    ### character length has been determined in "database/create-cpg-table.sql"
    if (stud_dat) {
        var_nam <- "schar"
    } else {
        var_nam <- "rchar"
    }
    lapply(max_nchars, function(n) {
        var <- get(paste0(var_nam, n))
        lapply(var, function(x) {
            all_vals <- as.character(dat[[x]])
            if (all(is.na(all_vals))) return(NULL)
            if (any(nchar(all_vals) > n)) {
                stop(paste("A value in the", x, "column in the data is too long", 
                          "please make sure it is", n, "characters or fewer."))
            }
        })
    })
}

check_required_cols <- function(dat, cols) 
{
    ### Checks columns for NAs and quits if there are NAs

    lapply(cols, function(col) {
        vals <- dat[[col]]
        if (any(is.na(vals))) {
            stop(paste("A value in the", col, "column in the data is missing", 
                      "and this is a required column."))
        } else {
            return(NULL)
        }
    })
}

get_outcome_and_exposure <- function(studies) 
{
    ### Use study data to define outcome and exposure
    ### and get units
    df <- studies
    if (df$dnam_in_model == "Outcome") {
        df$Outcome <- "DNA methylation"
        df$Outcome_Units <- df$dnam_units
        df$Exposure <- df$Trait
        df$Exposure_Units <- df$Trait_units
    } else {
        df$Exposure <- "DNA methylation"
        df$Exposure_Units <- df$dnam_units
        df$Outcome <- df$Trait
        df$Outcome_Units <- df$Trait_units
    }
    return(df)
}

sort_study_cols <- function(studies) 
{
    ### Change study columns to what they are in the 
    ### database
    df <- get_outcome_and_exposure(studies)
    df <- dplyr::mutate(df, Consortium = Cohorts_or_consortium, 
               Age = Age_group)
    df <- dplyr::select(df, one_of(out_studies_cols))
    return(df)
}

generate_study_id <- function(studies) 
{
    ### Generate studyid from data
    df <- studies
    auth_nam <- gsub(" ", "-", df$Author)
    trait_nam <- gsub(" ", "_", tolower(df$Trait))
    trait_nam <- gsub("(?!-)[[:punct:]]", "_", trait_nam, perl=TRUE)
    if (is.na(df$PMID)) {
        pmid <- NULL
    } else {
        pmid <- df$PMID
    }
    if (!is.na(df$Analysis)) {
        analysis <- gsub(" ", "_", tolower(df$Analysis))
        analysis <- gsub("(?!-)[[:punct:]]", "_", analysis, perl=TRUE)
    } else {
        analysis <- NULL
    }
        StudyID <- paste(c(pmid, auth_nam, trait_nam, analysis), collapse = "_")
    return(StudyID)
}

check_efo <- function(efo_terms) 
{
    ### check efo term(s) are in correct format
    if (is.na(efo_terms)) return(NULL)
    efos <- trimws(unlist(strsplit(efo_terms, ",")))
    if (length(efos) > 0) {
        check_split <- grepl("_", efos)
        if (!any(check_split)) {
            stop("EFO term(s) aren't entered correctly. They should be in the format: ONTOLOGY_ID 
                  and if there are multiple then they should be separated by commas.")
        }
    }
}

comma <- function(x) as.numeric(format(x, digits = 2, big.mark = ""))

load_results_file <- function(file, res_dir) 
{
    ### read in results file and check columns
    res_file_path <- file.path(res_dir, file)
    if (!file.exists(res_file_path)) stop("Results file not present!")
    res <- read.csv(res_file_path)
    if (all(colnames(res) != results_cols)) stop("Results columns don't match template")
    
    res <- res[res$CpG != "", ] # sometimes CpG column can be filled with empty cells
    res$Beta <- comma(res$Beta)
    res$SE <- comma(res$SE)
    res$P <- comma(res$P)

    return(res)
}

check_results_cols <- function(results) 
{
    ### check some specifics of results data
    if (!all(grepl("^c", results$CpG))) {
        stop("Some things that aren't CpGs are present in the CpG column of the results file")
    }
    if (any(results$P > 1) | any(results$P < 0)) {
        stop("Not all P values provided are between 0 and 1")
    }
    se <- results$SE[!is.na(results$SE)]
    if (any(sign(se) == -1)) {
        stop("Not all standard errors provided are positive")
    }
    return(NULL)
}

check_for_duplicates <- function(old_studies, sid)
{
    ### check the new studies file isn't entering duplicated data
    if (sid %in% old_studies$StudyID) {
        dup_sid <- sid[sid %in% old_studies$StudyID]
        stop(paste0("These study IDs are present in the database already: ", 
                    dup_sid))
    }
    return(NULL)
}

make_directory <- function(dir_to_make) 
{
    ### make new directory if it doesn't already exist
    if (file.exists(dir_to_make)) {
        return(NULL)
    } else {
        message("Making new directory: ", dir_to_make)
        system(paste("mkdir", dir_to_make))
    }
}

master_sort_function <- function(studies_dat) 
{
    ### master function for all data checks 
    check_required_cols(studies_dat, s_required_cols)
    res <- load_results_file(file = studies_dat$Results_file, res_dir = res_dir)
    studies_dat <- dplyr::select(studies_dat, -Results_file)
    check_efo(studies_dat$EFO)
    check_required_cols(res, r_required_cols)
    check_nchar(studies_dat, smax_chars, stud_dat = TRUE)
    check_nchar(res, rmax_chars, stud_dat = FALSE)
    check_results_cols(res)
    studies_dat <- sort_study_cols(studies_dat)
    sid <- generate_study_id(studies_dat)
    check_for_duplicates(old_studies, sid)
    res$StudyID <- studies_dat$StudyID <- sid
    full_res <- dplyr::left_join(res, cpg_annotations, by = c("CpG" = "CpG"))
    full_res <- dplyr::filter(full_res, P < 1e-4)
    full_res <- full_res[, c("CpG", "Location", "Chr", "Pos", "Gene", "Type", "Beta", "SE", "P", "Details", "StudyID")]
    sid_dir <- file.path(out_dir, sid)
    make_directory(dir_to_make = sid_dir)
    message("Writing out data to new directory")
    write.table(studies_dat, file = file.path(sid_dir, "studies.txt"), 
                col.names = TRUE, row.names = FALSE, quote = FALSE, sep = "\t")
    write.table(full_res, file = file.path(sid_dir, "results.txt"), 
                col.names = TRUE, row.names = FALSE, quote = FALSE, sep = "\t")
    message("Appending results directory to: ", studies_to_add_file)
    sid_to_add <- sid[!sid %in% studies_to_add]
    write.table(sid_to_add, file = file.path(file_dir, "ewas-sum-stats/studies-to-add.txt"),
            col.names = F, row.names = F, quote = F, sep = "\n", append = T)
    return(NULL)
}

# ----------------------------------------------------
# Setup for data checks
# ----------------------------------------------------

template_study_cols <- c("Author", 
                         "Cohorts_or_consortium", 
                         "PMID", 
                         "Date", 
                         "Trait", 
                         "EFO", 
                         "Trait_units", 
                         "dnam_in_model", 
                         "dnam_units", 
                         "Analysis", 
                         "Source", 
                         "Covariates", 
                         "Methylation_Array", 
                         "Tissue",
                         "Further_Details", 
                         "N", 
                         "N_Cohorts", 
                         "Age_group", 
                         "Sex", 
                         "Ethnicity", 
                         "Results_file")

out_studies_cols <- c("Author", 
                      "Consortium", 
                      "PMID", 
                      "Date", 
                      "Trait", 
                      "EFO", 
                      "Analysis", 
                      "Source", 
                      "Outcome", 
                      "Exposure", 
                      "Covariates", 
                      "Outcome_Units", 
                      "Exposure_Units", 
                      "Methylation_Array", 
                      "Tissue", 
                      "Further_Details", 
                      "N", 
                      "N_Cohorts", 
                      "Age",
                      "Sex",
                      "Ethnicity"
                    )

results_cols <- c("CpG", 
                  "Beta", 
                  "SE", 
                  "P", 
                  "Details")

s_required_cols <- c("Author", "Trait", "dnam_in_model", "dnam_units", "Methylation_Array", "Tissue", "Age_group", "Sex", "Ethnicity", "Results_file")
r_required_cols <- c("CpG", "P")

# max number of characters for each variable in the mysql database
rchar20 <- c("CpG", "Beta", "SE")
rchar50 <- c("P")
rchar200 <- c("Details")
rmax_chars <- c(20, 50, 200)

schar50 <- c("Author", "PMID", "Source", "Trait_Units", "dnam_units",
            "Methylation_Array")
schar20 <- c("Date", "N", "N_Cohorts", "Age_group", "Sex")
schar100 <- c("Tissue", "EFO")
schar300 <- "Covariates"
schar200 <- template_study_cols[!template_study_cols %in% c(schar50, schar20, schar100, schar300)]
smax_chars <- c(20, 50, 100, 200, 300)

# loading in the studies-to-add file so as to not duplicate additions
studies_to_add_file <- file.path(file_dir, "ewas-sum-stats/studies-to-add.txt")
studies_to_add <- readLines(studies_to_add_file)

# loading in old studies file so as to not duplicate data
old_stuides_file <- file.path(file_dir, "ewas-sum-stats/combined_data/studies.txt")
old_studies <- read.delim(old_stuides_file)
# create new study IDs for the old studies file as things may have changed
old_studies$StudyID <- unlist(lapply(1:nrow(old_studies), function(x) generate_study_id(old_studies[x,])))

# ----------------------------------------------------
# Run checks
# ----------------------------------------------------

# Check studies file column names
if (!all(colnames(studies) == template_study_cols)) {
    stop("Studies file column names do not match the template columns")
}

out <- lapply(1:nrow(studies), function(x) {
    message("Preparing row ", x, " of ", nrow(studies), " from the studies file.")
    df <- studies[x, ]
    out <- tryCatch(master_sort_function(df), error = function(e) return(e$message))
    if (!is.null(out)) {
        df$success <- FALSE
        df$message <- out
    } else {
        df$success <- TRUE
        df$message <- NA
    }
    return(df)
})

new_studies <- dplyr::bind_rows(out)
message(sum(new_studies$success), " / ", nrow(new_studies), " studies have been successfully prepared.")

# ----------------------------------------------------
# Clean inhouse-data directory and write out failed studies
# ----------------------------------------------------

# worth removing studies.xlsx??? -> I'm not so sure... just write over it each time.

message("Removing successful results files from ", res_dir)
lapply(1:nrow(new_studies), function(x) {
    df <- new_studies[x, ]
    if (!df$success) return(NULL)

    to_rm <- file.path(res_dir, df$Results_file)
    system(paste("rm", to_rm))
    out_msg <- message("Removed results file: ", to_rm)
    return(out_msg)
})

failed_studies <- new_studies[!new_studies$success, ]
today <- Sys.Date()
out_nam <- paste0("failed_studies_", today, ".tsv")
out_path <- file.path(inhouse_dir, out_nam)

if (!nrow(failed_studies) == 0) {
    message("Writing out failed studies to ", out_path)
    write.table(failed_studies, file = out_path, 
            col.names = T, row.names = F, quote = F, sep = "\t")    
} else {
    message("There were no failed studies!! Happy days!!")
}

# FIN
