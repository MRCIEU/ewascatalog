rm(list=ls())
options(stringsAsFactors = F)
setwd("O:/Documents/Projects/EWAS catalog/Catalog/Results/28814982")
data <- read.csv("28814982.csv", stringsAsFactors=F)
data$se <- (data$uci-data$lci)/(2*1.96)
data$p <- 2*pnorm(-abs(data$beta/data$se))
data$se <- round(data$se,3)
data$p <- signif(data$p, 3)
data$i2 <- ""
data$p_het <- ""
data$details <- ""
write.csv(data, paste0("28814982.csv"), row.names=F)