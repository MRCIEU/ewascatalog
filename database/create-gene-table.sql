DROP TABLE IF EXISTS `genes`;

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
