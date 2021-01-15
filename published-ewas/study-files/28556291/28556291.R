rm(list=ls())
options(stringsAsFactors = F)
setwd("O:/Documents/Projects/EWAS catalog/Catalog/Results/28556291")
data <- read.csv("28556291.csv", stringsAsFactors=F)
data$se <- round(abs(data$beta/(qnorm(data$p/2))),6)

for(i in c("26w", "13w", "Avg")){
  tmp <- data[grepl(i, data$exp),]
  results <- tmp
  results$i2 <- ""
  results$p_het <- ""
  results$details <- sub("\\?", "Sum ",results$exp)
  results$details <- sub("26w ", "", results$details)
  results$details <- sub("13w ", "", results$details)
  results$details <- sub("Avg ", "", results$details)
  results <- results[,c("cpg", "beta", "se", "p", "i2", "p_het", "details")]
  write.csv(results, paste0("28556291_",i,".csv"), row.names=F)
}
