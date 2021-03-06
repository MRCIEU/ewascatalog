rm(list=ls())
options(stringsAsFactors = F)
setwd("O:/Documents/Projects/EWAS catalog/Catalog/Results/27015559")
for (i in list.files()[grepl(".csv",list.files())]){
  data <- read.csv(i)
  data$i2 <- ""
  data$p_het <- ""
  data$details <- ""
  data$beta <- log(data$hr)
  data$se <- round(abs(data$beta/qnorm(data$p/2)),4)
  data$se[is.na(data$se)] <- NA
  data$se[data$se==0] <- NA
  data$beta <- round(data$beta,6)
  data$p <- signif(data$p,4)
  data <- data[, c("cpg", "beta", "se", "p", "i2", "p_het", "details")]
  write.csv(data, paste0(sub(".csv","", i),"_1.csv"), row.names=F)
}