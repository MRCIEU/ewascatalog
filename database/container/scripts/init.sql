
-- Create database
CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME};
USE ${DATABASE_NAME};

SET GLOBAL local_infile = 1;

-- Create user
CREATE USER IF NOT EXISTS '${DATABASE_USER}'@'%' IDENTIFIED BY '${DATABASE_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DATABASE_NAME}.* TO '${DATABASE_USER}'@'%';
FLUSH PRIVILEGES;

--
-- create 'cpgs' table
CREATE TABLE IF NOT EXISTS cpgs (
  cpg varchar(20) DEFAULT NULL,
  chrpos varchar(20) DEFAULT NULL,
  chr varchar(2) DEFAULT NULL,
  pos int(10) DEFAULT NULL,
  gene varchar(200) DEFAULT NULL,
  type varchar(20) DEFAULT NULL,
  KEY cpg (cpg),
  KEY chrpos (chrpos)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPRESSED;

LOAD DATA LOCAL INFILE '/data/cpg_annotation.txt'
INTO TABLE cpgs
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

--
-- create 'genes' table 

CREATE TABLE `genes` (
  `gene` varchar(30) DEFAULT NULL,
  `ensembl_id` varchar(20) DEFAULT NULL,
  `chr` varchar(2) DEFAULT NULL,
  `start` int(20) DEFAULT NULL,
  `end` int(20) DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `gene` (`gene`),
  KEY `ensembl_id` (`ensembl_id`)
) ENGINE=InnoDB AUTO_INCREMENT=29354 DEFAULT CHARSET=latin1;

LOAD DATA LOCAL INFILE '/data/gene_annotation.txt'
INTO TABLE genes
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

--
-- create 'studies' table

CREATE TABLE `studies` (
`author` varchar(50),
`consortium` varchar(200),
`pmid` varchar(50),
`date` varchar(20),
`trait` varchar(200),
`efo` varchar(100),
`analysis` varchar(200),
`source` varchar(50),
`outcome` varchar(200),
`exposure` varchar(200),
`covariates` varchar(300),
`outcome_units` varchar(50),
`exposure_units` varchar(50),
`methylation_array` varchar(100),
`tissue` varchar(100),
`further_details` varchar(200),
`n` varchar(20),
`n_cohorts` varchar(20),
-- `categories` varchar(200),
`age` varchar(50),
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

--
-- create 'results' table to store summary statistics

CREATE TABLE `results` (
`cpg` varchar(20),
`beta` varchar(20),
`se` varchar(20),
`p` varchar(50),
`details` varchar(200),
`study_id` varchar(200),
FOREIGN KEY (`study_id`) REFERENCES `studies` (`study_id`),
KEY `cpg` (`cpg`)
)
ROW_FORMAT=COMPRESSED;

--
-- create 'last_update' table to store date of last update

CREATE TABLE IF NOT EXISTS last_update (
    update_date DATE NOT NULL
);

INSERT INTO last_update (update_date) VALUES (CURDATE());

--
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
