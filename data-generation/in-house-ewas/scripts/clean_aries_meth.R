# -------------------------------------------------------
# Filter ARIES betas
# -------------------------------------------------------
# Version = v4

# -------------------------------------------------------
# Setup
# -------------------------------------------------------

pkgs <- c("tidyverse", "meffil", "GenABEL")
lapply(pkgs, require, character.only = T)

source("scripts/read_filepaths.R")
source("scripts/useful_functions.R")

read_filepaths("filepaths.sh")

setwd(bc_home_dir)

# ---------------------------------------------
# load in data! 
# ---------------------------------------------

# aries ids file
aries_ids <- read_tsv(paste0("data/alspac/", aries_ids_file))
# pcs
pcs <- read.table(paste0("data/alspac/", timepoints, "/", timepoints, "_pcs.eigenvec"), sep = " ", header = F, stringsAsFactors = F) 
head(pcs)
colnames(pcs) <- c("FID", "IID", paste0(rep("PC", times = 20), 1:20))
pcs$ALN <- gsub("[A-Z]", "", pcs[["FID"]])
pcs <- dplyr::select(pcs, -IID, -FID)
pc_cols <- colnames(pcs)[colnames(pcs) != "ALN"]

# samplesheet
load(samplesheet_file)
head(samplesheet)
samplesheet <- samplesheet %>%
	dplyr::filter(ALN %in% aries_ids$ALN & time_point == timepoints)

# methylation data 
load(aries_meth_dat)
meth <- beta[, samplesheet$Sample_Name]
rm(beta)

# detection p values
load(aries_detection_p)
pvals <- detection.p[, samplesheet$Sample_Name]
rm(detection.p)

# list from zhou et al. --> copy from rdsf directory
zhou_list <- read.delim("data/retain_from_zhou.txt", header = F)
zhou_list <- as.character(zhou_list[[1]])

# -------------------------------------------------------
# remove potentially faulty probes
# -------------------------------------------------------

#load annotation data
annotation <- meffil.get.features("450k")

#Filter meth data (remove sex chromosomes and SNPs and probes with high detection P-values)
pvalue_over_0.05 <- pvals > 0.05
count_over_0.05 <- rowSums(sign(pvalue_over_0.05))
Probes_to_exclude_Pvalue <- rownames(pvals)[which(count_over_0.05 > ncol(pvals) * 0.05)]
XY <- as.character(annotation$name[which(annotation$chromosome %in% c("chrX", "chrY"))])
SNPs.and.controls <- as.character(annotation$name[-grep("cg|ch", annotation$name)])
annotation<- annotation[-which(annotation$name %in% c(XY, SNPs.and.controls, Probes_to_exclude_Pvalue)), ]
meth <- subset(meth, row.names(meth) %in% annotation$name)
paste("There are now ", nrow(meth), " probes")
paste(length(XY), "were removed because they were XY")
paste(length(SNPs.and.controls), "were removed because they were SNPs/controls")
paste(length(Probes_to_exclude_Pvalue), "were removed because they had a high detection P-value")
rm(XY, SNPs.and.controls, pvals, count_over_0.05, pvalue_over_0.05, Probes_to_exclude_Pvalue)

filtered_vars <- c("detection_p_values", "on_XY", "SNPs/controls")

# Retain from zhou
meth <- meth[rownames(meth) %in% zhou_list, ]
dim(meth)

q <- rowQuantiles(meth, probs = c(0.25, 0.75), na.rm = T)
iqr <- q[, 2] - q[, 1]
too.hi <- which(meth > q[,2] + 3 * iqr, arr.ind=T)
too.lo <- which(meth < q[,1] - 3 * iqr, arr.ind=T)
if (nrow(too.hi) > 0) meth[too.hi] <- NA
if (nrow(too.lo) > 0) meth[too.lo] <- NA

samp <- colnames(meth)

# rank transform the methylation data...
# meth <- apply(meth, 1, rntransform)
# meth <- t(meth)
# colnames(meth) <- samp

# double check samples being used... 
dim(meth)
num_na <- apply(meth, 2, function(x){sum(is.na(x))})
rem_samp <- which(num_na > (0.05 * nrow(meth)))
meth <- meth[, -rem_samp]
dim(meth)

print(paste0("Number of samples removed = ", length(rem_samp)))

out_nam <- file.path("data/alspac", timepoints, "cleaned_meth_data.RData")
save(meth, file = out_nam)

print("Saved filtered methylation data")

