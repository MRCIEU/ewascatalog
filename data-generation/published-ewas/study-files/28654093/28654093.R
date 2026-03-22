rm(list=ls())
options(stringsAsFactors = F)
setwd("O:/Documents/Projects/EWAS catalog/Catalog/Results/28654093")
for (i in list.files()[grepl(".csv",list.files())]){
  data <- read.csv(i)
  data$i2 <- ""
  data$p_het <- ""
  data$details <- ""
  data$se <- round(abs(data$beta/qnorm(data$p/2)),4)
  data <- data[, c("cpg", "beta", "se", "p", "i2", "p_het", "details")]
  write.csv(data, paste0(i), row.names=F)
}