args <- commandArgs(trailingOnly = TRUE)
pkgs_file <- args[1]
outfile <- args[2]

pkgs <- read.csv(pkgs_file)

cran <- pkgs$cran[pkgs$cran != ""]
bioc <- pkgs$bioc[pkgs$bioc != ""]
git <- pkgs$git[pkgs$git != ""]

for (pkg in cran) {
  cat("R package:", pkg, "\n")
  installed <- installed.packages()[,"Package"]
  if (!pkg %in% installed)
     install.packages(pkg)
}

for (pkg in bioc) {
  cat("R package:", pkg, "\n")
  installed <- installed.packages()[,"Package"]
  if (!pkg %in% installed)
    BiocManager::install(pkg)
}

for (url in git) {
  installed <- installed.packages()[,"Package"]
  pkg <- basename(url)
  cat("R package:", pkg, "\n")
  if (!pkg %in% installed)
    devtools::install_github(url)
}    

save(pkgs, file = outfile)