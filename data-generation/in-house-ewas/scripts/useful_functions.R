# -------------------------------------------------------
# Useful functions for EWAS
# -------------------------------------------------------

# -------------------------------------------------------
# SVA functions
# -------------------------------------------------------

# impute function from Matt
impute_matrix <- function(x, FUN = function(x) rowMedians(x, na.rm = T)) {
    idx <- which(is.na(x), arr.ind = T)
    if (length(idx) > 0) {
        v <- FUN(x)
        v[which(is.na(v))] <- FUN(matrix(v, nrow = 1))
        x[idx] <- v[idx[, "row"]]
    }
    return(x)
}

# function to add quotes for weird trait names
addq <- function(x) paste0("`", x, "`")

out_failed <- function(x, out_path) {
	sink(file = paste0(out_path, "sv_fails.txt"), append = TRUE, split = TRUE)
	print(x)
	sink()
}

generate_svs <- function(trait, phen_data, meth_data, covariates = "", nsv, out_path, 
						 samples = "Sample_Name") {
	print(trait)
	out_nam <- paste0(out_path, trait, ".txt")
	if (file.exists(out_nam)) {
		message(out_nam, " exists so moving on")
		return(NULL)
	}
	phen <- phen_data %>%
		dplyr::select(one_of(samples), one_of(trait, covariates)) %>%
		.[complete.cases(.), ]
	
	mdat <- meth_data[, colnames(meth_data) %in% phen[[samples]]]
	phen <- phen %>%
		dplyr::filter(!!as.symbol(samples) %in% colnames(mdat))
	
	# models 
	trait_mod <- paste0("~ ", addq(trait))
	cov_mod <- paste(covariates, collapse = " + ")
	if (covariates != "") {
		full_mod <- paste(trait_mod, cov_mod, sep = " + ")
		fom <- as.formula(full_mod)
		# null model
		fom0 <- as.formula(paste0("~ ", cov_mod))
		mod0 <- model.matrix(fom0, data = phen)
	} else {
		fom <- as.formula(trait_mod)
		mod0 <- NULL
	}

	# full model - with variables of interest 
	mod <- model.matrix(fom, data = phen)

	# Estimate the surrogate variables
	tryCatch({
		svobj <- smartsva.cpp(mdat, mod, mod0, n.sv = nsv, VERBOSE = T)
		svs <- as.data.frame(svobj$sv, stringsAsFactors = F)
		svs[[samples]] <- phen[[samples]]
		# head(svs)
		colnames(svs)[1:nsv] <- paste0("sv", 1:nsv)

		write.table(svs, file = paste0(out_path, trait, ".txt"),
					sep = "\t", quote = F, col.names = T, row.names = F)

	}, error = function(e) {out_failed(trait, out_path)})
}

# -------------------------------------------------------
# Checking data functions
# -------------------------------------------------------

is.binary <- function(v) {
  x <- unique(v)
  length(x) - sum(is.na(x)) == 2L
}

# set outliers to missing
set_outliers_to_na <- function(x) {
	q <- quantile(x, probs = c(0.25, 0.75), na.rm = T)
	iqr <- q[2] - q[1]
	too_hi <- which(x > q[2] + 3 * iqr)
	too_lo <- which(x < q[1] - 3 * iqr)
	if (length(c(too_lo,too_hi)) > 0) x[c(too_lo, too_hi)] <- NA
	return(x)
}

# -------------------------------------------------------
# Reading and writing data functions
# -------------------------------------------------------

# loading function that allows you to name the thing being loaded into R
new_load <- function(file) {
	temp_space <- new.env()
	var <- load(file, temp_space)
	out <- get(var, temp_space)
	rm(temp_space)
	return(out)
}

make_dir <- function(path) {
    system(paste("mkdir", path))
}

