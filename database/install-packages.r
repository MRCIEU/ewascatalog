pkgs <- list(cran=c("devtools", "Hmisc", "BiocManager", "data.table", "dplyr", "cluster", "readxl"),
             bioc="biomaRt",
             git=c("https://github.com/perishky/rmdreport", "https://github.com/perishky/meffil", "https://github.com/perishky/ewaff"))

for (pkg in pkgs$cran) {
  cat("R package:", pkg, "\n")
  installed <- installed.packages()[,"Package"]
  if (!pkg %in% installed)
     install.packages(pkg)
}

for (pkg in pkgs$bioc) {
  cat("R package:", pkg, "\n")
  installed <- installed.packages()[,"Package"]
  if (!pkg %in% installed)
    BiocManager::install(pkg)
}

for (url in pkgs$git) {
  installed <- installed.packages()[,"Package"]
  pkg <- basename(url)
  cat("R package:", pkg, "\n")
  if (!pkg %in% installed)
    devtools::install_github(url)
}    

