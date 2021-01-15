# -------------------------------------------------
# Sorting geo phenotypes for EWAS - manual sorting of data
# -------------------------------------------------

## pkgs
library(tidyverse) # tidy code and data
library(readxl) # reading in excel spreadsheets

source("scripts/read_filepaths.R")
source("scripts/useful_functions.R")

read_filepaths("filepaths.sh")

devtools::load_all("~/repos/usefunc")

# read in messy list -- ASSUMES YOU ARE SORTING ON SAME DAY AS WRITING IT OUT!
file_nam <- paste0("data/geo/messy_geo_data_to_sort_", Sys.Date(), ".RData")
messy_dat <- new_load(file_nam)

geo_asc <- messy_dat$geo_asc
effect_phen_dat <- messy_dat$effect_phen_dat
pub_dat <- messy_dat$pub_dat

## currently struture of script is as follows:
### Each time a new set of GEO data is extracted, a new section is added
### There are subsections of each timepoint where values are checked and 
### any manual changes are made! -- could change to a script per timepoint?

#
#
# Timepoint 1: 2019-04
#
#

# ---------------------------------------
# Check values for each variable
# ---------------------------------------

# check each VoI. Want to check that:
#   1. that the values are as expected
#   2. it needs to be split into different variables
#   3. duplication of samples

# to ask about:
# 1. 
# 3. --> do I split by biopsy region??
# 12. --> can't see age (check phen_list[[geo_asc[12]]])
# 13. --> can't see recurrance and recurrance time variables...
# 17. --> Just do adjacent vs. all the others? (what do the numbers mean??)
# 22. --> comment mentions "multiple datasets", as in multiple GEO datasets???
# 23. --> comment mentions "multiple datasets", as in multiple GEO datasets???
# 26. --> comment mentions should split by cell type. Some cell types have <100 individuals
#         the cell types are just blood cell types, so would SVs account for these differences?
# 28. --> What is the control group?
# 30. --> remove unclassified and bin normal and normal_hepatocyte together?
# 32. --> How is birthweight coded as 0 and 1???
# 36. --> Got 4 ages... Treat as continuous??
# 42. --> what are the scales of the different measurements??
# 46. --> no variable of interest, wtf?!?
# 48. --> comment: "Paper used a discovery and replication cohort, so need to check numbers to see if they have uploaded the data for both. Clearly no column to help define them though"

# checking the phenotypes!
ga <- geo_asc[1]
pub_dat[pub_dat$geo.accession == ga, "comment", drop = T]
effect_phen_dat[ga]
str(effect_phen_dat[ga])
table(effect_phen_dat[[ga]][[2]])

omit_for_now <- c(1,3,12,13,17,22,23,26,28,30,32,36,42,46,48)
effect_phen_dat <- effect_phen_dat[-omit_for_now]

geo_asc <- names(effect_phen_dat)
# check there are no duplicated samples
map_lgl(geo_asc, function(ga) {
    some_dat <- effect_phen_dat[[ga]]
    any(duplicated(some_dat[["sample_name"]]))
})
# all goooooood boi! 

# ---------------------------------------
# manual changes to the datasets to revalue the variables
# ---------------------------------------

# changes to make
effect_phen_dat[["GSE107080"]] <- effect_phen_dat[["GSE107080"]] %>%
    mutate(idu_and_hcv_dx = case_when(idu == 1 & hcv_dx == 1 ~ "pos", 
                                      idu == 0 & hcv_dx == 0 ~ "neg")) %>%
    dplyr::filter(!is.na(idu_and_hcv_dx)) %>%
    dplyr::select(sample_name, idu_and_hcv_dx)

effect_phen_dat[["GSE112596"]] <- effect_phen_dat[["GSE112596"]] %>%
    dplyr::filter(therapy != "GA")

effect_phen_dat[["GSE113725"]] <- effect_phen_dat[["GSE113725"]] %>%
    mutate(depression_status = case_when(groupid == 1 | groupid == 2 ~ "control", 
                                         groupid == 3 | groupid == 4 ~ "case")) %>%
    dplyr::select(sample_name, depression_status)

effect_phen_dat[["GSE50660"]] <- effect_phen_dat[["GSE50660"]] %>% 
    mutate(smoking_status_nf = 
        case_when(`smoking (0, 1 and 2, which represent never, former and current smokers)` == 0 ~ "never", 
                  `smoking (0, 1 and 2, which represent never, former and current smokers)` == 1 ~ "former")) %>%
    mutate(smoking_status_nc = 
        case_when(`smoking (0, 1 and 2, which represent never, former and current smokers)` == 0 ~ "never", 
                  `smoking (0, 1 and 2, which represent never, former and current smokers)` == 2 ~ "current")) %>%
    mutate(smoking_status_fc = 
        case_when(`smoking (0, 1 and 2, which represent never, former and current smokers)` == 1 ~ "former", 
                  `smoking (0, 1 and 2, which represent never, former and current smokers)` == 2 ~ "current")) %>%
    dplyr::select(-`smoking (0, 1 and 2, which represent never, former and current smokers)`)

effect_phen_dat[["GSE53740"]] <- effect_phen_dat[["GSE53740"]] %>%
    mutate(FTD_status = case_when(diagnosis == "FTD" ~ "FTD", 
                                  diagnosis == "Control" ~ "Control")) %>%
    mutate(PSP_status = case_when(diagnosis == "PSP" ~ "PSP", 
                                  diagnosis == "Control" ~ "Control")) %>%
    dplyr::select(-diagnosis)

effect_phen_dat[["GSE59592"]] <- effect_phen_dat[["GSE59592"]] %>%
    dplyr::filter(!(`afb1 exposure` %in% c("dry", "rainy")))

effect_phen_dat[["GSE60275"]] <- effect_phen_dat[["GSE60275"]] %>%
    dplyr::filter(healthy_vs_disease != "healthy")

effect_phen_dat[["GSE67530"]] <- effect_phen_dat[["GSE67530"]] %>%
    dplyr::filter(ards != "NA")

effect_phen_dat[["GSE69502"]] <- effect_phen_dat[["GSE69502"]] %>% 
    mutate(anencephaly_status = case_when(`ntd status` == "anencephaly" ~ "anencephaly", 
                                          `ntd status` == "control" ~ "control")) %>% 
    mutate(spina_bifida_status = case_when(`ntd status` == "spina bifida" ~ "spina_bifida", 
                                           `ntd status` == "control" ~ "control")) %>%
    dplyr::select(-`ntd status`)

effect_phen_dat[["GSE71678"]] <- effect_phen_dat[["GSE71678"]] %>%
    dplyr::filter(`placental as levels` != "NA")

effect_phen_dat[["GSE87640"]] <- effect_phen_dat[["GSE87640"]] %>% 
    mutate(UC_diagnosis = case_when(full_diagnosis == "UC" ~ "UC",
                                    full_diagnosis %in% c("HC", "HL", "IB", "OT") ~ "healthy")) %>%
    mutate(CD_diagnosis = case_when(full_diagnosis == "CD" ~ "CD", 
                                    full_diagnosis %in% c("HC", "HL", "IB", "OT") ~ "healthy")) %>%
    mutate(IBD_diagnosis = case_when(full_diagnosis %in% c("CD", "UC") ~ "IBD", 
                                     full_diagnosis %in% c("HC", "HL", "IB", "OT") ~ "healthy")) %>%
    dplyr::select(-full_diagnosis)

# write it all out!
clean_out_list <- list(geo_asc = geo_asc, 
					   effect_phen_dat = effect_phen_dat, 
					   pub_dat = pub_dat)

out_nam <- paste0("data/geo/clean_geo_data_to_sort_", Sys.Date(), ".RData")
save(clean_out_list, file = out_nam)

#
#
# Timepoint 2: 2020-11
#
#

# ---------------------------------------
# Check values for each variable
# ---------------------------------------

# check there are no duplicated samples
map_lgl(geo_asc, function(ga) {
    some_dat <- effect_phen_dat[[ga]]
    any(duplicated(some_dat[["sample_name"]]))
})
# all goooooood boi! 

# check phenotypes manually!
ga <- geo_asc[4]
pub_dat[pub_dat$accession == ga, "comment", drop = T]
effect_phen_dat[ga]
str(effect_phen_dat[ga])
table(effect_phen_dat[[ga]][[2]])

## seems to be nothing to do here! 
clean_out_list <- list(geo_asc = geo_asc, 
                       effect_phen_dat = effect_phen_dat, 
                       pub_dat = pub_dat)

out_nam <- paste0("data/geo/clean_geo_data_to_sort_", Sys.Date(), ".RData")
save(clean_out_list, file = out_nam)


