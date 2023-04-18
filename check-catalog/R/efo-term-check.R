# --------------------------------------------------------
# Check EFO terms
# --------------------------------------------------------

## 2022-01-06 update: discontinuing this script and EFO checks as there is a bit of a problem connecting to
## 					  the EBI api. The search requires we connect to it for every EFO term and if that 

## pkgs
library(tidyverse) # tidy data and code
library(rols) # to connect efo terms to labels

## args
args <- commandArgs(trailingOnly = TRUE)
studies_file <- args[1]
outfile <- args[2]

# studies_file <- "data/studies2022-01-06.txt.gz"
# outfile <- "data/bad-efos.RData"

## data
studies <- read_tsv(studies_file)

# --------------------------------------------------------
# Check the terms
# --------------------------------------------------------
get_efo_term_fails <- function(efo_terms)
{
	### Input = vector of EFO terms
	### Output = vector of EFO terms that aren't in the OLS database
	### Uses the "rols" package to search the OLS and extract labels
	faulty_terms <- lapply(efo_terms, function(x) {
		print(x)
		attempt <- 1
		qry <- try(OlsSearch(q = x, exact = TRUE))
		while (inherits(qry, "try-error")) {
			attempt <- attempt + 1
			message("attempt: ", attempt, " at connecting to the EBI API.")
			qry <- try(OlsSearch(q = x, exact = TRUE))
		}
		if (qry@numFound == 0) return(x)
		
		return(NULL)
	})
	out <- unlist(faulty_terms)
	return(out)
}

efos <- lapply(unique(studies$StudyID), function(id) {
	studs <- studies[studies$StudyID == id, ]
	out <- unique(str_squish(unlist(str_split(studs$EFO, ","))))	
	return(out)
})
names(efos) <- unique(studies$StudyID)
efos <- efos[!is.na(efos)]

bad_efos <- get_efo_term_fails(unlist(efos))

bad_efo_studies <- map_dfr(names(efos), function(id) {
	efo <- efos[[id]]
	if (!any(efo %in% bad_efos)) {
		return(NULL)
	} else {
		studs <- studies[studies$StudyID %in% id, ]
		return(studs)
	}
})


out <- list(bad_efos = bad_efos, 
			bad_efo_studies = bad_efo_studies)

save(out, file = outfile)