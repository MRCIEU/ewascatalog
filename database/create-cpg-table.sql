DROP TABLE IF EXISTS `cpgs`;

CREATE TABLE `cpgs` (
  `cpg` varchar(20) DEFAULT NULL,
  `chrpos` varchar(20) DEFAULT NULL,
  `chr` varchar(2) DEFAULT NULL,
  `pos` int(10) DEFAULT NULL,
  `gene` varchar(200) DEFAULT NULL,
  `type` varchar(20) DEFAULT NULL,
  KEY `cpg` (`cpg`),
  KEY `chrpos` (`chrpos`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPRESSED;
