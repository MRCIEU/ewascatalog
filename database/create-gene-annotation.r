########################################################################
## Genes database                                                     ##
##                                                                    ##
## James Staley                                                       ##
## Cardiovascular Epidemiology Unit                                   ##
## Cambridge University                                               ## 
## jrs95@medschl.cam.ac.uk                                            ##
##                                                                    ##
## Last updated 19th April 2017                                       ##
########################################################################

args <- commandArgs(trailingOnly=TRUE)
filename <- args[1]

##### Libraries ######
library(data.table)
library(biomaRt)

##### Working directory #####
#setwd()

##########################################################
##### Ensembl #####
##########################################################

##### Get mart #####
ensembl <- useMart("ENSEMBL_MART_ENSEMBL", host="grch37.ensembl.org", path="/biomart/martservice", dataset="hsapiens_gene_ensembl")

##### Loop over chromosomes #####
data <- data.frame()

for(i in as.character(1:22)){
  chr <- getBM(attributes=c('ensembl_gene_id','ensembl_transcript_id','hgnc_symbol','chromosome_name','start_position','end_position','gene_biotype'), filters='chromosome_name', values=i, mart=ensembl)
  data <- rbind(data, chr)
}

##########################################################
##### Format file #####
##########################################################

##### Remove MicroRNA #####
data <- data[!grepl("^MIR", data$hgnc_symbol),]

##### Remove Ribosomal protein #####
data <- data[!grepl("^RP", data$hgnc_symbol),]

##### Remove duplicates #####
data <- data[data$hgnc_symbol!="",c("ensembl_gene_id", "hgnc_symbol", "chromosome_name", "start_position", "end_position", "gene_biotype")]
#data <- data[!duplicated(data),]

# Tabulate duplicates
data[duplicated(data$hgnc_symbol) | duplicated(data$hgnc_symbol, fromLast=T),]
data[duplicated(data$ensembl_gene_id) | duplicated(data$ensembl_gene_id, fromLast=T),]
data <- data[!duplicated(data$hgnc_symbol),]

# UGT2A1
data$end_position[data$hgnc_symbol=="UGT2A1"] <- 70518967 

##### Format #####
data <- data[, c("hgnc_symbol", "ensembl_gene_id", "gene_biotype", "chromosome_name", "start_position", "end_position")]
names(data) <- c("gene", "ensembl_id", "gene_type", "chr", "start", "end")
data_genes <- data[data$gene_type=="protein_coding",]
data <- data[,c("gene", "ensembl_id", "chr", "start", "end")]
data_genes <- data_genes[,c("gene", "ensembl_id", "chr", "start", "end")]

##### Save #####
#write.table(data, "../../genes/genes_b37.txt", row.names=F, quote=F, sep="\t")
#write.table(data_genes, "../../genes/genes_b37_pc.txt", row.names=F, quote=F, sep="\t")
write.table(data_genes, file=filename, row.names=F, quote=F, sep="\t")
