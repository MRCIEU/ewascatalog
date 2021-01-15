###################################################################
## Process EWAS                                                  ##
##                                                               ##
## James Staley                                                  ##
## University of Bristol                                         ##
## Email: james.staley@bristol.ac.uk                             ##
###################################################################

###################################################################
##### Set-up #####
###################################################################

args <- commandArgs(trailingOnly=TRUE)
filename <- args[1]

##### Options #####
options(stringsAsFactors = F)

##### Set working directory #####
#setwd()

##### Libraries ####
library(data.table)
library(Hmisc)
library(dplyr)
library(meffil)

###################################################################
##### Methylation annotation #####
###################################################################

# 450k array
annotation_450 <- meffil.get.features("450k")
names(annotation_450)[names(annotation_450)=="name"] <- "CpG"
names(annotation_450)[names(annotation_450)=="chromosome"] <- "Chr"
annotation_450$Chr <- sub("chr", "", annotation_450$Chr)
names(annotation_450)[names(annotation_450)=="position"] <- "Pos"
annotation_450$Location <- paste0("chr", annotation_450$Chr, ":", annotation_450$Pos)
annotation_450$Gene <- unlist(lapply(annotation_450$gene.symbol, function(x){paste(unique(unlist(strsplit(x, ";"))), collapse=";")}))
annotation_450$Gene[annotation_450$Gene==""] <- "-"
annotation_450$Type <- annotation_450$relation.to.island
annotation_450$Type <- gsub("_", " ", annotation_450$Type); annotation_450$Type <- capitalize(tolower(annotation_450$Type))
annotation_450$Type <- sub("N", "North", annotation_450$Type); annotation_450$Type <- sub("S", "South", annotation_450$Type); annotation_450$Type <- sub("sea", " sea", annotation_450$Type)
annotation_450 <- annotation_450[,c("CpG", "Location", "Chr", "Pos", "Gene", "Type")]

# EPIC array
annotation_epic <- meffil.get.features("epic")
names(annotation_epic)[names(annotation_epic)=="name"] <- "CpG"
names(annotation_epic)[names(annotation_epic)=="chromosome"] <- "Chr"
annotation_epic$Chr <- sub("chr", "", annotation_epic$Chr)
names(annotation_epic)[names(annotation_epic)=="position"] <- "Pos"
annotation_epic$Location <- paste0("chr", annotation_epic$Chr, ":", annotation_epic$Pos)
annotation_epic$Gene <- unlist(lapply(annotation_epic$gene.symbol, function(x){paste(unique(unlist(strsplit(x, ";"))), collapse=";")}))
annotation_epic$Gene[annotation_epic$Gene==""] <- "-"
annotation_epic$Type <- annotation_epic$relation.to.island
annotation_epic$Type <- gsub("_", " ", annotation_epic$Type); annotation_epic$Type <- capitalize(tolower(annotation_epic$Type))
annotation_epic$Type <- sub("N", "North", annotation_epic$Type); annotation_epic$Type <- sub("S", "South", annotation_epic$Type); annotation_epic$Type <- sub("sea", " sea", annotation_epic$Type)
annotation_epic <- annotation_epic[,c("CpG", "Location", "Chr", "Pos", "Gene", "Type")]

# Combined
annotation <- rbind(annotation_450, annotation_epic)
annotation <- annotation[match(unique(annotation$CpG), annotation$CpG),]
annotation <- annotation[grepl("^c", annotation$CpG),]
annotation[annotation==""] <- "-"; annotation[is.na(annotation)] <- "-"
write.table(annotation, file=filename, row.names=F, quote=F, sep="\t")

q("no")
