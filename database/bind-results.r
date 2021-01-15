# ----------------------------------------
# binding all results and study files
# ----------------------------------------

# 
args <- commandArgs(trailingOnly = TRUE)
file_dir <- args[1]

pkgs <- c("purrr", "data.table") # may have to add purrr to the installed packages at the start!
lapply(pkgs, require, character.only = TRUE)

setwd(file_dir)

published_dir <- "ewas-sum-stats/published"
# full summary stats directory with results subsetted to P<1x10-4
sub_dir <- "ewas-sum-stats/sub"
all_sub_dirs <- list.dirs(sub_dir)
all_sub_dirs <- all_sub_dirs[all_sub_dirs != sub_dir]
all_dirs <- c(published_dir, all_sub_dirs)
out_dir <- "ewas-sum-stats/combined_data"

# ----------------------------------------
# bind the study files
# ----------------------------------------
study_dat <- lapply(all_dirs, function(dir) {
	df <- fread(file.path(dir, "studies.txt"))
	return(df)
})
study_dat <- do.call(rbind, study_dat)

write.table(study_dat, file = file.path(out_dir, "studies.txt"), 
			col.names = T, row.names = F, quote = F, sep = "\t")
rm(study_dat)

# ----------------------------------------
# bind the results files
# ----------------------------------------
res_dat <- lapply(all_dirs, function(dir) {
	df <- fread(file.path(dir, "results.txt"))
	return(df)
})
res_dat <- do.call(rbind, res_dat)

res_dat <- res_dat %>%
	mutate(Beta = round(as.numeric(Beta), 6), 
		   SE = round(as.numeric(SE), 6), 
		   P = signif(P, 3))

write.table(res_dat, file = file.path(out_dir, "results.txt"), 
			col.names = T, row.names = F, quote = F, sep = "\t")

