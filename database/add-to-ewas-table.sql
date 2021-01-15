DROP TABLE IF EXISTS `new_results`;
DROP TABLE IF EXISTS `new_studies`;

CREATE TABLE `new_studies` (
`author` varchar(50),
`consortium` varchar(50),
`pmid` varchar(20),
`date` varchar(20),
`trait` varchar(200),
`efo` varchar(100),
`analysis` varchar(200),
`source` varchar(50),
`outcome` varchar(200),
`exposure` varchar(200),
`covariates` varchar(300),
`outcome_unit` varchar(50),
`exposure_unit` varchar(50),
`array` varchar(50),
`tissue` varchar(100),
`further_details` varchar(200),
`n` varchar(20),
`n_studies` varchar(20),
-- `categories` varchar(200),
`age` varchar(20),
`sex` varchar(20),
-- `n_males` varchar(20),
-- `n_females` varchar(20),
`ethnicity` varchar(200),
-- `n_eur` varchar(20),
-- `n_eas` varchar(20),
-- `n_sas` varchar(20),
-- `n_afr` varchar(20),
-- `n_amr` varchar(20),
-- `n_oth` varchar(20),
`study_id` varchar(200),
PRIMARY KEY (`study_id`),
KEY `efo` (`efo`)
)
ROW_FORMAT=COMPRESSED;


CREATE TABLE `new_results` (
`cpg` varchar(20),
`chrpos` varchar(20),
`chr` varchar(20),
`pos` int(20),
`gene` varchar(200),
`type` varchar(20),
`beta` varchar(20),
`se` varchar(20),
`p` varchar(50),
`details` varchar(200),
`study_id` varchar(200),
FOREIGN KEY (`study_id`) REFERENCES `new_studies` (`study_id`),
KEY `cpg` (`cpg`),
KEY `chrpos` (`chrpos`),
KEY `chr` (`chr`),
KEY `pos` (`pos`)
)
ROW_FORMAT=COMPRESSED;  	

