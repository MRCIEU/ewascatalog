rm(list=ls())
options(stringsAsFactors = F)
setwd("O:/Documents/Projects/EWAS catalog/Catalog/Results/28785368")
for (i in list.files()[grepl(".csv",list.files())]){
  data <- read.csv(i)
  data$p <- signif(data$p, 3)
  data$i2 <- ""
  data$p_het <- ""
  data$details <- ""
  data$beta <- ""
  data$se <- ""
  data <- data[, c("cpg", "beta", "se", "p", "i2", "p_het", "details")]
  write.csv(data, paste0(i), row.names=F)
}