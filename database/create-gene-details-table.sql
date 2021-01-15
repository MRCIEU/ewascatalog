DROP TABLE IF EXISTS `gene_details`;

CREATE TABLE `gene_details` AS 
  select `gene`, COUNT(DISTINCT `cpg`) as `nsites` FROM `cpgs` GROUP BY `gene`;
