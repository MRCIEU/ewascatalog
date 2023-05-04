# ----------------------------------------------------
# Assign papers to individuals
# ----------------------------------------------------


# read in papers

# get papers from this month

# assign them out randomly to people 


## pkgs
library(tidyverse) # tidy code and data
library(readxl) # read in excel files
library(openxlsx) # write excel files
library(lubridate) # easy dealing with dates

recruits <- readLines("recruits-data/recruits.txt")

# ----------------------------------------------------
# read in data and filter based to this month
# ----------------------------------------------------

today <- Sys.Date()
ext_date <- today ## Extraction date -- change if not today - keep in format "YYYY-mm-dd"
input_data_file <- paste0("ewas-catalog-data-to-enter-", ext_date, ".xlsx")
input_data <- read_xlsx(file.path("data-to-enter", input_data_file))

this_year <- year(as.POSIXlt(ext_date, format="%y-%m-%d"))
this_month <- month(as.POSIXlt(ext_date, format="%y-%m-%d"))

input_data$year <- year(as.POSIXlt(input_data$Date, format="%y-%m-%d"))
input_data$month <- month(as.POSIXlt(input_data$Date, format="%y-%m-%d"))

data_this_month <- input_data %>%
	dplyr::filter(year == this_year & month == this_month) 

# ----------------------------------------------------
# assign papers to one person from this month
# ----------------------------------------------------

create_folder <- function(folder) system(paste0("mkdir -p ", "'", folder, "'"))

# change individual if needs be
ind <- "Paul Yousefi"

if (!(ind %in% recruits)) {
	stop("The name of the individual who is going to extract emails from the newly published papers is not within the recruits listed.")
}

paul_data <- data_this_month %>% 
	mutate(assigned_to = ind, to_contact = "", comments = "", 
		   cor_author = "", email = "", `added (y/n)` = "") %>%
	dplyr::select(-year, -month)

out_folder <- file.path("recruits-data", ind, ext_date)
create_folder(out_folder)
out_file <- paste0("papers-to-add-", ext_date, ".xlsx")
write.xlsx(paul_data, file = file.path(out_folder, out_file))

# ----------------------------------------------------
# assign papers to each recruit from previous months
# ----------------------------------------------------

recruits <- recruits[recruits != ind]
recruits <- trimws(recruits)

## Assign 2 papers per person
out_data <- input_data %>%
	arrange(Date) %>%
	dplyr::filter(!PMID %in% data_this_month$PMID) %>%
	.[1:(length(recruits)*2), ] %>%
	mutate(assigned_to = rep(recruits, length.out = (length(recruits)*2)), 
		   n = "", `added (y/n)` = "", comments = "") %>%
	dplyr::select(pmid = PMID, date = Date, title = Title, assigned_to, `added (y/n)`, comments)

# rec <- "Abigail Lay"
# ext_date <- "2021-04-26"
lapply(recruits, function(rec) {
	print(rec)
	out_folder <- file.path("recruits-data", rec, ext_date)
	create_folder(out_folder)
	out_file <- paste0("papers-to-add-", ext_date, ".xlsx")
	out <- out_data %>%
		dplyr::filter(assigned_to == rec)
	write.xlsx(out, file = file.path(out_folder, out_file))
})