rm(list=ls())
options(stringsAsFactors = F)
setwd("O:/Documents/Projects/EWAS catalog/Catalog/Results/24500968")
for (i in list.files()[grepl(".csv",list.files())]){
  data <- read.csv(i)
  data$beta <- ""
  data$se <- ""
  data$p <- signif(data$p,3)
  data$i2 <- ""
  data$p_het <- ""
  data$details <- ""
  write.csv(data, paste0(i), row.names=F)
}