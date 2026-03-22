# --------------------------------------- 
# script to read filepaths and vars given right script!
# ---------------------------------------

read_filepaths <- function(filepath_file) {	
	dat <- readLines(filepath_file)
	# remove comments and blank spaces
	to_rm <- c("", grep("#", dat, value = TRUE))
	dat <- dat[!dat %in% to_rm]
	x <- strsplit(dat, "=")
	len_x <- length(x)
	len_ls <- length(ls(envir = globalenv()))
	lapply(seq_along(x), function(i) {
		var_name <- x[[i]][1]
		var <- x[[i]][2]
		if (grepl('', var)) gsub("'", "", var)
		assign(var_name, var, envir = globalenv())
		return(NULL)
	})
	new_len_ls <- length(ls(envir = globalenv()))
	if (new_len_ls != len_ls + len_x) stop("DIDNEEE WORK!")
}