-- MySQL dump 10.13  Distrib 5.6.32, for osx10.10 (x86_64)
--
-- Host: prod.mysql.nypl.org    Database: archive
-- ------------------------------------------------------
-- Server version	5.1.44-community-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `file_store`
--

DROP TABLE IF EXISTS `file_store`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `file_store` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `FILE_NAME` varchar(45) NOT NULL,
  `CHECKSUM` varchar(128) NOT NULL,
  `FILE_ID` varchar(64) DEFAULT NULL,
  `TIME_STAMP` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `TYPE` varchar(2) NOT NULL,
  `W` float DEFAULT '0',
  `H` float DEFAULT '0',
  `STATUS` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `SRC` varchar(4) DEFAULT '0',
  `IID` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `UUID` varchar(45) NOT NULL,
  `CDATE` date NOT NULL,
  `SIZE` bigint(20) unsigned DEFAULT NULL,
  `QUAR` tinyint(1) NOT NULL DEFAULT '0',
  `last_check` date DEFAULT NULL,
  `fault` tinyint(1) unsigned zerofill DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `FILE_ID_TYPE` (`FILE_ID`,`TYPE`),
  KEY `UUID` (`UUID`),
  KEY `time_stamp` (`TIME_STAMP`),
  KEY `Lastcheck` (`last_check`) USING BTREE,
  KEY `fault` (`fault`),
  KEY `idx_fs_checksum` (`CHECKSUM`),
  KEY `idx_typestatus_fileid` (`TYPE`,`STATUS`,`FILE_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=23877214 DEFAULT CHARSET=latin1 COMMENT='InnoDB free: 1451008 kB';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `infrastructure`
--

DROP TABLE IF EXISTS `infrastructure`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `infrastructure` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `IP` varchar(45) DEFAULT NULL,
  `HOSTNAME` varchar(45) DEFAULT NULL,
  `PATH` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-02-08 16:36:36
