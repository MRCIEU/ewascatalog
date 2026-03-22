# ---------------------------------------------
# Generating GEO studies data manually
# ---------------------------------------------

## For alspac data this is done manually in an excel spreadsheet, 
## but as the geo data first needs cleaning on bc3, it's easier to
## just manually do it on here! 

library(tidyverse)

source("scripts/read_filepaths.R")
source("scripts/useful_functions.R")

read_filepaths("filepaths.sh")

devtools::load_all("~/repos/usefunc")

# read in accession data AND meta data
geo_asc <- read_tsv("data/geo/geo_accession.txt", col_names=F)
geo_asc <- geo_asc[[1]]

met_dat <- lapply(geo_asc, function(ga) {
	met_path <- file.path("data/geo", ga, "phenotype_metadata.txt")
	read_tsv(met_path)
})
names(met_dat) <- geo_asc

pheno_dat <- lapply(geo_asc, function(ga) {
	phen_path <- file.path("data/geo", ga, "cleaned_phenotype_data.txt")
	read_tsv(phen_path)
})	
names(pheno_dat) <- geo_asc

# ---------------------------------------------
# sort it all out manually! 
# ---------------------------------------------

# columns that need looking at:
# --- Trait
# --- EFO
# --- Trait_units
# --- Tissue
# --- Age_group (Infants, Children, Adults, Geriatrics)
# --- Sex (Males, Females, Both)
# --- Ethnicity (European, East Asian, South Asian, African, Admixed, Other, Unclear)

as.data.frame(met_dat[[10]])

met_dat[[1]]$Trait <- "Age"
met_dat[[1]]$EFO <- "EFO_0000246"
met_dat[[1]]$Trait_units <- "Years"
met_dat[[1]]$Tissue <- "Breast"
met_dat[[1]]$Age_group <- "Adults"
met_dat[[1]]$Sex <- "Females"
met_dat[[1]]$Ethnicity <- "European, African"

met_dat[[2]]$Trait <- "Multiple sclerosis"
met_dat[[2]]$EFO <- "EFO_0003885"
met_dat[[2]]$Trait_units <- ""
met_dat[[2]]$Tissue <- "Whole blood"
met_dat[[2]]$Age_group <- "Young adults"
met_dat[[2]]$Sex <- "Both"
met_dat[[2]]$Ethnicity <- "Unclear"

met_dat[[3]]$Trait <- "Intravenous illicit drug use and hepatitis C infection"
met_dat[[3]]$EFO <- "EFO_0007010, EFO_0003047"
met_dat[[3]]$Trait_units <- ""
met_dat[[3]]$Tissue <- "Whole blood"
met_dat[[3]]$Age_group <- "Adults"
met_dat[[3]]$Sex <- "Males"
met_dat[[3]]$Ethnicity <- "African"

met_dat[[4]]$Trait <- "Fetal intolerance of labor"
met_dat[[4]]$EFO <- ""
met_dat[[4]]$Trait_units <- ""
met_dat[[4]]$Tissue <- "Whole blood"
met_dat[[4]]$Age_group <- "Adults"
met_dat[[4]]$Sex <- "Females"
met_dat[[4]]$Ethnicity <- "Unclear"

met_dat[[5]]$Trait <- "Arsenic exposure"
met_dat[[5]]$EFO <- "CHEBI_27563"
met_dat[[5]]$Trait_units <- ""
met_dat[[5]]$Tissue <- "Whole blood"
met_dat[[5]]$Age_group <- "Adults"
met_dat[[5]]$Sex <- "Both"
met_dat[[5]]$Ethnicity <- "East Asian"

met_dat[[6]]$Trait <- "Multiple sclerosis treatment"
met_dat[[6]]$EFO <- "EFO_0003885"
met_dat[[6]]$Trait_units <- ""
met_dat[[6]]$Tissue <- "Whole blood"
met_dat[[6]]$Age_group <- "Adults"
met_dat[[6]]$Sex <- "Both"
met_dat[[6]]$Ethnicity <- "Unclear"
met_dat[[6]]$Analysis <- paste0(met_dat[[6]]$Analysis, ". ", "Fumaric acid ester-treated MS patients vs treatment naive patients")
nchar(met_dat[[6]]$Analysis) < 200

met_dat[[7]]$Trait <- "Depression"
met_dat[[7]]$EFO <- "MONDO_0002050, EFO_0003761, MONDO_0002009"
met_dat[[7]]$Trait_units <- ""
met_dat[[7]]$Tissue <- "Whole blood"
met_dat[[7]]$Age_group <- "Adults"
met_dat[[7]]$Sex <- "Both"
met_dat[[7]]$Ethnicity <- "European"

## EXCLUDE 8!!
met_dat[[8]]$Trait <- "Systemic lupus erythematosus"
met_dat[[8]]$EFO <- "EFO_0002690"
met_dat[[8]]$Trait_units <- ""
met_dat[[8]]$Tissue <- ""
met_dat[[8]]$Age_group <- ""
met_dat[[8]]$Sex <- ""
met_dat[[8]]$Ethnicity <- c("")

met_dat[[9]]$Trait <- "Tissue"
met_dat[[9]]$EFO <- ""
met_dat[[9]]$Trait_units <- ""
met_dat[[9]]$Tissue <- "Buccal cells and peripheral blood mononuclear cells"
met_dat[[9]]$Age_group <- "Children"
met_dat[[9]]$Sex <- "Both"
met_dat[[9]]$Ethnicity <- "European"
met_dat[[9]]$Analysis <- paste0(met_dat[[9]]$Analysis, ". ", "Tissue types are buccal epithelial cells and peripheral blood mononuclear cells")
nchar(met_dat[[9]]$Analysis) < 200

met_dat[[10]]$Trait <- "Ethnicity"
met_dat[[10]]$EFO <- "EFO_0001799"
met_dat[[10]]$Trait_units <- ""
met_dat[[10]]$Tissue <- "Lymphoblasts"
met_dat[[10]]$Age_group <- "Adults"
met_dat[[10]]$Sex <- "Both"
met_dat[[10]]$Ethnicity <- "European, African"
met_dat[[10]]$Analysis <- paste0(met_dat[[10]]$Analysis, ". ", "Compared European and African samples from HapMap (CEU and YRI)")
nchar(met_dat[[10]]$Analysis) < 200

met_dat[[11]]$Trait <- "Age"
met_dat[[11]]$EFO <- "EFO_0000246"
met_dat[[11]]$Trait_units <- "Years"
met_dat[[11]]$Tissue <- "Whole blood"
met_dat[[11]]$Age_group <- "Adults"
met_dat[[11]]$Sex <- "Both"
met_dat[[11]]$Ethnicity <- "Unclear"

met_dat[[12]]$Trait <- "Rheumatoid arthritis"
met_dat[[12]]$EFO <- "EFO_0000685"
met_dat[[12]]$Trait_units <- ""
met_dat[[12]]$Tissue <- "Whole blood"
met_dat[[12]]$Age_group <- "Adults"
met_dat[[12]]$Sex <- "Both"
met_dat[[12]]$Ethnicity <- "European"

met_dat[[13]]$Trait <- c("Smoking", "Smoking", "Smoking")
met_dat[[13]]$EFO <- c("EFO_0004318, EFO_0005671, EFO_0006527", "EFO_0004318, EFO_0005671, EFO_0006527", "EFO_0004318, EFO_0005671, EFO_0006527") 
met_dat[[13]]$Trait_units <- c("", "", "")
met_dat[[13]]$Tissue <- c("Whole blood", "Whole blood", "Whole blood")
met_dat[[13]]$Age_group <- c("Adults", "Adults", "Adults")
met_dat[[13]]$Sex <- c("Both", "Both", "Both")
met_dat[[13]]$Ethnicity <- c("European", "European", "European")
met_dat[[13]]$Analysis <- c(paste0(met_dat[[13]]$Analysis[1], ". ", "Never vs former smokers"), 
							paste0(met_dat[[13]]$Analysis[2], ". ", "Never vs current smokers"), 
							paste0(met_dat[[13]]$Analysis[3], ". ", "Former vs current smokers"))

met_dat[[14]]$Trait <- "Age at menarche"
met_dat[[14]]$EFO <- "EFO_0004703"
met_dat[[14]]$Trait_units <- "Years"
met_dat[[14]]$Tissue <- "Whole blood"
met_dat[[14]]$Age_group <- "Adults"
met_dat[[14]]$Sex <- "Females"
met_dat[[14]]$Ethnicity <- "European"

met_dat[[15]]$Trait <- "Smoking"
met_dat[[15]]$EFO <- "EFO_0004318, EFO_0005671, EFO_0006527"
met_dat[[15]]$Trait_units <- ""
met_dat[[15]]$Tissue <- "Peripheral blood mononuclear cells"
met_dat[[15]]$Age_group <- "Adults"
met_dat[[15]]$Sex <- "Females"
met_dat[[15]]$Ethnicity <- "African"

met_dat[[16]]$Trait <- c("Frontotemporal dementia", "Progressive supranuclear palsy")
met_dat[[16]]$EFO <- c("Orphanet_282", "Orphanet_683")
met_dat[[16]]$Trait_units <- ""
met_dat[[16]]$Tissue <- c("Whole blood", "Whole blood")
met_dat[[16]]$Age_group <- c("Geriatrics", "Geriatrics")
met_dat[[16]]$Sex <- c("Both", "Both")
met_dat[[16]]$Ethnicity <- c("Unclear", "Unclear")

met_dat[[17]]$Trait <- "Fetal brain development"
met_dat[[17]]$EFO <- "GO_0007420"
met_dat[[17]]$Trait_units <- "Days post-conception"
met_dat[[17]]$Tissue <- "Fetal brain"
met_dat[[17]]$Age_group <- "Infants"
met_dat[[17]]$Sex <- "Both"
met_dat[[17]]$Ethnicity <- "Unclear"

met_dat[[18]]$Trait <- "Age"
met_dat[[18]]$EFO <- "EFO_0000246"
met_dat[[18]]$Trait_units <- ""
met_dat[[18]]$Tissue <- "Whole blood"
met_dat[[18]]$Age_group <- "Geriatrics"
met_dat[[18]]$Sex <- "Both"
met_dat[[18]]$Ethnicity <- "European"
met_dat[[18]]$Analysis <- paste0(met_dat[[18]]$Analysis, ". ", "Compared nonagenarians to adults aged 19-30")

met_dat[[19]]$Trait <- "Aflotoxin B1 exposure"
met_dat[[19]]$EFO <- "CHEBI_2504"
met_dat[[19]]$Trait_units <- "pg/mg albumin"
met_dat[[19]]$Tissue <- "Whole blood"
met_dat[[19]]$Age_group <- "Infants"
met_dat[[19]]$Sex <- "Both"
met_dat[[19]]$Ethnicity <- "African"

met_dat[[20]]$Trait <- "Sex"
met_dat[[20]]$EFO <- "PATO_0000047"
met_dat[[20]]$Trait_units <- ""
met_dat[[20]]$Tissue <- "Whole blood"
met_dat[[20]]$Age_group <- "Adults"
met_dat[[20]]$Sex <- "Both"
met_dat[[20]]$Ethnicity <- "Unclear"

met_dat[[21]]$Trait <- "Age"
met_dat[[21]]$EFO <- "EFO_0000246"
met_dat[[21]]$Trait_units <- ""
met_dat[[21]]$Tissue <- "Fetal liver, adult liver"
met_dat[[21]]$Age_group <- "Adults"
met_dat[[21]]$Sex <- "Both"
met_dat[[21]]$Ethnicity <- "European"
met_dat[[21]]$Analysis <- paste0(met_dat[[21]]$Analysis, ". ", "Compared fetal liver tissue to adult liver tissue of different individuals")

met_dat[[22]]$Trait <- "Alzheimer's disease"
met_dat[[22]]$EFO <- "EFO_0000249"
met_dat[[22]]$Trait_units <- ""
met_dat[[22]]$Tissue <- "Brain"
met_dat[[22]]$Age_group <- "Geriatrics"
met_dat[[22]]$Sex <- "Both"
met_dat[[22]]$Ethnicity <- "Unclear"
met_dat[[22]]$Further_Details <- "Some brain tissue was cell sorted, but all data analysed together for this re-analysis of GEO data."

met_dat[[23]]$Trait <- "Sex"
met_dat[[23]]$EFO <- "PATO_0000047"
met_dat[[23]]$Trait_units <- ""
met_dat[[23]]$Tissue <- "Whole blood"
met_dat[[23]]$Age_group <- "Adults"
met_dat[[23]]$Sex <- "Both"
met_dat[[23]]$Ethnicity <- "East Asian"

met_dat[[24]]$Trait <- "Acute respiratory distress syndrome"
met_dat[[24]]$EFO <- "EFO_1000637"
met_dat[[24]]$Trait_units <- ""
met_dat[[24]]$Tissue <- "Whole blood"
met_dat[[24]]$Age_group <- "Adults"
met_dat[[24]]$Sex <- "Both"
met_dat[[24]]$Ethnicity <- "European, African"

# Maybe exclude this too?? --YUP 
met_dat[[25]]$Trait <- c("Anencephaly", "Spina bifida")
met_dat[[25]]$EFO <- c("MONDO_0000819", "EFO_0003105")
met_dat[[25]]$Trait_units <- c("", "")
met_dat[[25]]$Tissue <- c("Chronic Villi, kidney, spinal cord, brain, muscle", "Chronic Villi, kidney, spinal cord, muscle")
met_dat[[25]]$Age_group <- c("Infants", "Infants")
met_dat[[25]]$Sex <- c("Both", "Both")
met_dat[[25]]$Ethnicity <- c("Unclear", "Unclear")
met_dat[[25]]$Further_Details <- "Combination of all tissue types used for analysis"

met_dat[[26]]$Trait <- "Oral or pharyngeal squamous cell carcinoma"
met_dat[[26]]$EFO <- "EFO_1001965, EFO_0000199"
met_dat[[26]]$Trait_units <- ""
met_dat[[26]]$Tissue <- "Saliva"
met_dat[[26]]$Age_group <- "Adults"
met_dat[[26]]$Sex <- "Both"
met_dat[[26]]$Ethnicity <- "Unclear"

met_dat[[27]]$Trait <- "Arsenic exposure"
met_dat[[27]]$EFO <- "CHEBI_27563"
met_dat[[27]]$Trait_units <- "ug/kg"
met_dat[[27]]$Tissue <- "Placenta"
met_dat[[27]]$Age_group <- "Infants"
met_dat[[27]]$Sex <- "Both"
met_dat[[27]]$Ethnicity <- "Unclear"

met_dat[[28]]$Trait <- "Graves' disease"
met_dat[[28]]$EFO <- "EFO_0004237"
met_dat[[28]]$Trait_units <- ""
met_dat[[28]]$Tissue <- "T cells"
met_dat[[28]]$Age_group <- "Adults"
met_dat[[28]]$Sex <- "Both"
met_dat[[28]]$Ethnicity <- "Unclear"

met_dat[[29]]$Trait <- "Psoriasis"
met_dat[[29]]$EFO <- "EFO_0000676"
met_dat[[29]]$Trait_units <- ""
met_dat[[29]]$Tissue <- "Skin"
met_dat[[29]]$Age_group <- "Adults"
met_dat[[29]]$Sex <- "Both"
met_dat[[29]]$Ethnicity <- "Unclear"

met_dat[[30]]$Trait <- "Prostate cancer"
met_dat[[30]]$EFO <- "MONDO_0008315"
met_dat[[30]]$Trait_units <- ""
met_dat[[30]]$Tissue <- "Prostate cancer tissue, benign prostate tissue"
met_dat[[30]]$Age_group <- "Adults"
met_dat[[30]]$Sex <- "Males"
met_dat[[30]]$Ethnicity <- "Unclear"

met_dat[[31]]$Trait <- "Fetal alcohol spectrum disorder"
met_dat[[31]]$EFO <- "MONDO_0000408"
met_dat[[31]]$Trait_units <- ""
met_dat[[31]]$Tissue <- "Buccal cells"
met_dat[[31]]$Age_group <- "Children"
met_dat[[31]]$Sex <- "Both"
met_dat[[31]]$Ethnicity <- "Unclear"

met_dat[[32]]$Trait <- "Alzheimer's disease"
met_dat[[32]]$EFO <- "EFO_0000249"
met_dat[[32]]$Trait_units <- ""
met_dat[[32]]$Tissue <- "Brain cortex"
met_dat[[32]]$Age_group <- "Geriatrics"
met_dat[[32]]$Sex <- "Both"
met_dat[[32]]$Ethnicity <- "Unclear"

met_dat[[33]]$Trait <- "Asthma"
met_dat[[33]]$EFO <- "EFO_0000270"
met_dat[[33]]$Trait_units <- ""
met_dat[[33]]$Tissue <- "Airway epithelial cells"
met_dat[[33]]$Age_group <- "Adults"
met_dat[[33]]$Sex <- "Both"
met_dat[[33]]$Ethnicity <- "European, African"

met_dat[[34]]$Trait <- c("Ulcerative colitis", "Crohn's disease", "Inflammatory bowel disease")
met_dat[[34]]$EFO <- c("EFO_0000729", "EFO_0000384", "EFO_0003767")
met_dat[[34]]$Trait_units <- c("", "", "")
met_dat[[34]]$Tissue <- c("Whole blood", "Whole blood", "Whole blood")
met_dat[[34]]$Age_group <- c("Adults", "Adults", "Adults")
met_dat[[34]]$Sex <- c("Both", "Both", "Both")
met_dat[[34]]$Ethnicity <- c("European", "European", "European")

met_dat[[35]]$Trait <- "Total body naevus count"
met_dat[[35]]$EFO <- "EFO_0000625"
met_dat[[35]]$Trait_units <- ""
met_dat[[35]]$Tissue <- "Skin"
met_dat[[35]]$Age_group <- "Adults"
met_dat[[35]]$Sex <- "Both"
met_dat[[35]]$Ethnicity <- "European"

# ---------------------------------------------
# Remove any shite stuff and write out res
# ---------------------------------------------

## Exclude GSE118144 and GSE69502
bad_ga <- c("GSE118144", "GSE69502")
out_geo_asc <- geo_asc[!geo_asc %in% bad_ga]

# write out and meta data
lapply(out_geo_asc, function(ga) {
    meta_dat <- met_dat[[ga]]
 
    out_path <- file.path("data/geo", ga)

    if (!file.exists(out_path)) make_dir(out_path)

    meta_nam <- file.path(out_path, "phenotype_metadata.txt")
    write.table(meta_dat, file = meta_nam,
                col.names = T, row.names = F, quote = F, sep = "\t")
    
    return(NULL)
})

# write out geo accession numbers being used
write.table(out_geo_asc, file = "data/geo/geo_accession.txt", 
            col.names = F, row.names = F, quote = F, sep = "\t")
