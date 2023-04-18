# ----------------------------------------------------
# Check results to be uploaded to The EWAS Catalog
# ----------------------------------------------------

## Aim: Take csv files and assess whether they are in the correct format to be uploaded to The EWAS Catalog

## Note: In order to run this script:
## 1. Make sure all your results are in one folder and there is nothing else in that folder
## 2. Run the script using instructions for Mac/Linux or Windows below:
##	  If you are using Linux/Mac, from the command line run:
##		  Rscript test-results.R "PATH-TO-RESULTS-FOLDER"
## 	  If you are using Windows, run this in a separate script in Rstudio:
##	   	  commandArgs <- function(...) "PATH-TO-RESULTS-FOLDER"
##		  source("test-results.R")

## Date: 2022-01-07

## arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 1) stop("There should only be one argument")
path_to_res <- args[1]
# path_to_res <- "test"

setwd(path_to_res)

# ----------------------------------------------------
# File name checks
# ---------------------------------------------------- 

res_files <- list.files()

## Do files have distinct names?
any_dup <- any(duplicated(res_files))
if (any_dup) stop("Duplicated files found. Each results file should have a unique name.")

## Are the files all csv files?
get_extension <- function(file) 
{
	ex <- strsplit(basename(file), split = "\\.")[[1]]
	return(ex[-1])
}

ext <- sapply(res_files, get_extension)
if (!all(ext == "csv")) {
	bad_ext <- ext[ext != "csv"]
	stop(paste("Not all file extensions end in csv. Here are the files that don't: ", paste(names(bad_ext), collapse = ", ")))
}

message("File name checks complete.")

# ----------------------------------------------------
# Contents checks
# ---------------------------------------------------- 

## Function for loading file and checking column names
rcols <- c("CpG", "Beta", "SE", "P", "Details")
load_results_file <- function(file, results_cols = rcols) 
{
	res <- read.csv(file)
	colnames(res)[colnames(res) == "X...CpG"] <- "CpG" # sometimes odd thing with csv files
	res <- res[, !grepl("^X", colnames(res))] # sometimes empty extra columns are added
	stop_msg <- paste("Results columns don't match template. Here are your results columns: ", paste(colnames(res), collapse = ", "))
	if (any(colnames(res) != results_cols)) stop(stop_msg)

	res <- res[res$CpG != "", ] # sometimes CpG column can be filled with empty cells
	return(res)
}

## Function for checking column classes
check_col_class <- function(res)
{
	correct_class <- list(CpG = "character", 
						  Beta = c("integer", "numeric", "double", "logical"), 
						  SE = c("integer", "numeric", "double", "logical"), 
						  P = c("numeric", "integer", "double"), 
						  Details = c("character", "logical"))

	lapply(seq_along(res), function(x) {
		colnam <- colnames(res)[x]
		col_class <- class(res[[colnam]])
		if (!col_class %in% correct_class[[colnam]]) {
			stop(paste("The class of the", colnam, "column is", col_class, 
					   ". It should be", paste(correct_class[[colnam]], collapse = ", ")))
		}
	})
	return(NULL)
}

## Function for checking contents of results files
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

check_required_cols <- function(dat, cols = c("CpG", "P")) 
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


## Time to check that content
out <- lapply(res_files, function(file) {
	message("\nChecking the file: ", file, "\n")
	res <- load_results_file(file)
	check_col_class(res)
	check_results_cols(res)
	check_required_cols(res)
	message("\nFinished checking the file: ", file, "\n")
})



