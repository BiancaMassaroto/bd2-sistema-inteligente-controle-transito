-- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: sistema_transito
-- ------------------------------------------------------
-- Server version	5.5.5-10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `ciclo_semaforo`
--

DROP TABLE IF EXISTS `ciclo_semaforo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ciclo_semaforo` (
  `iddispositivos` int(11) NOT NULL,
  `verde` int(11) DEFAULT NULL,
  `amarelo` int(11) DEFAULT NULL,
  `vermelho` int(11) DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`iddispositivos`),
  CONSTRAINT `fk_ciclo_semaforo_dispositivo1` FOREIGN KEY (`iddispositivos`) REFERENCES `dispositivo` (`iddispositivos`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ciclo_semaforo`
--

LOCK TABLES `ciclo_semaforo` WRITE;
/*!40000 ALTER TABLE `ciclo_semaforo` DISABLE KEYS */;
/*!40000 ALTER TABLE `ciclo_semaforo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cidade`
--

DROP TABLE IF EXISTS `cidade`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cidade` (
  `idcidade` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(45) DEFAULT NULL,
  `idestado` int(11) NOT NULL,
  PRIMARY KEY (`idcidade`),
  KEY `fk_cidade_estado_idx` (`idestado`),
  CONSTRAINT `fk_cidade_estado` FOREIGN KEY (`idestado`) REFERENCES `estado` (`idestado`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cidade`
--

LOCK TABLES `cidade` WRITE;
/*!40000 ALTER TABLE `cidade` DISABLE KEYS */;
/*!40000 ALTER TABLE `cidade` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dispositivo`
--

DROP TABLE IF EXISTS `dispositivo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dispositivo` (
  `iddispositivos` int(11) NOT NULL AUTO_INCREMENT,
  `tipo` varchar(45) DEFAULT NULL,
  `ativo` tinyint(4) DEFAULT NULL,
  `idlogs` int(11) DEFAULT NULL,
  `idlocal` int(11) NOT NULL,
  PRIMARY KEY (`iddispositivos`),
  KEY `fk_dispositivos_local1_idx` (`idlocal`),
  CONSTRAINT `fk_dispositivos_local1` FOREIGN KEY (`idlocal`) REFERENCES `local` (`idlocal`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dispositivo`
--

LOCK TABLES `dispositivo` WRITE;
/*!40000 ALTER TABLE `dispositivo` DISABLE KEYS */;
/*!40000 ALTER TABLE `dispositivo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dispositivos_incidentes`
--

DROP TABLE IF EXISTS `dispositivos_incidentes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dispositivos_incidentes` (
  `iddispositivos` int(11) NOT NULL,
  `idincidentes` int(11) NOT NULL,
  PRIMARY KEY (`iddispositivos`,`idincidentes`),
  KEY `fk_dispositivo_has_evento_trafego_evento_trafego1_idx` (`idincidentes`),
  KEY `fk_dispositivo_has_evento_trafego_dispositivo1_idx` (`iddispositivos`),
  CONSTRAINT `fk_dispositivo_has_evento_trafego_dispositivo1` FOREIGN KEY (`iddispositivos`) REFERENCES `dispositivo` (`iddispositivos`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_dispositivo_has_evento_trafego_evento_trafego1` FOREIGN KEY (`idincidentes`) REFERENCES `evento_trafego` (`id_evento`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dispositivos_incidentes`
--

LOCK TABLES `dispositivos_incidentes` WRITE;
/*!40000 ALTER TABLE `dispositivos_incidentes` DISABLE KEYS */;
/*!40000 ALTER TABLE `dispositivos_incidentes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `estado`
--

DROP TABLE IF EXISTS `estado`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `estado` (
  `idestado` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(45) DEFAULT NULL,
  `sigla` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`idestado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `estado`
--

LOCK TABLES `estado` WRITE;
/*!40000 ALTER TABLE `estado` DISABLE KEYS */;
/*!40000 ALTER TABLE `estado` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `evento_trafego`
--

DROP TABLE IF EXISTS `evento_trafego`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `evento_trafego` (
  `id_evento` int(11) NOT NULL AUTO_INCREMENT,
  `descricao` varchar(280) DEFAULT NULL,
  `tipo` varchar(50) DEFAULT NULL,
  `duracao` varchar(45) DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  `idlocal` int(11) NOT NULL,
  PRIMARY KEY (`id_evento`),
  KEY `fk_evento_trafego_local1_idx` (`idlocal`),
  CONSTRAINT `fk_evento_trafego_local1` FOREIGN KEY (`idlocal`) REFERENCES `local` (`idlocal`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evento_trafego`
--

LOCK TABLES `evento_trafego` WRITE;
/*!40000 ALTER TABLE `evento_trafego` DISABLE KEYS */;
/*!40000 ALTER TABLE `evento_trafego` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fluxo_trafego`
--

DROP TABLE IF EXISTS `fluxo_trafego`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fluxo_trafego` (
  `id_fluxo` datetime NOT NULL,
  `qtd_veiculos` int(11) DEFAULT NULL,
  `velocidade_media` decimal(10,2) DEFAULT NULL,
  `sentido` varchar(45) DEFAULT NULL,
  `id_dispositivo` int(11) NOT NULL,
  PRIMARY KEY (`id_fluxo`),
  KEY `fk_fluxo_trafego_dispositivo1_idx` (`id_dispositivo`),
  CONSTRAINT `fk_fluxo_trafego_dispositivo1` FOREIGN KEY (`id_dispositivo`) REFERENCES `dispositivo` (`iddispositivos`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fluxo_trafego`
--

LOCK TABLES `fluxo_trafego` WRITE;
/*!40000 ALTER TABLE `fluxo_trafego` DISABLE KEYS */;
/*!40000 ALTER TABLE `fluxo_trafego` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `funcionario`
--

DROP TABLE IF EXISTS `funcionario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `funcionario` (
  `idfuncionarios` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`idfuncionarios`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `funcionario`
--

LOCK TABLES `funcionario` WRITE;
/*!40000 ALTER TABLE `funcionario` DISABLE KEYS */;
/*!40000 ALTER TABLE `funcionario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `local`
--

DROP TABLE IF EXISTS `local`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `local` (
  `idlocal` int(11) NOT NULL AUTO_INCREMENT,
  `logradouro` varchar(45) DEFAULT NULL,
  `bairro` varchar(45) DEFAULT NULL,
  `CEP` int(11) DEFAULT NULL,
  `idcidade` int(11) NOT NULL,
  PRIMARY KEY (`idlocal`),
  KEY `fk_local_cidade1_idx` (`idcidade`),
  CONSTRAINT `fk_local_cidade1` FOREIGN KEY (`idcidade`) REFERENCES `cidade` (`idcidade`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `local`
--

LOCK TABLES `local` WRITE;
/*!40000 ALTER TABLE `local` DISABLE KEYS */;
/*!40000 ALTER TABLE `local` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `logs_dispositivos`
--

DROP TABLE IF EXISTS `logs_dispositivos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `logs_dispositivos` (
  `iddispositivos` int(11) NOT NULL,
  `idfuncionarios` int(11) NOT NULL,
  `idlogs_dispositivoscol` int(11) NOT NULL,
  `descricao_log` varchar(45) DEFAULT NULL,
  `data_log` date DEFAULT NULL,
  `horario_log` time DEFAULT NULL,
  PRIMARY KEY (`idlogs_dispositivoscol`,`iddispositivos`,`idfuncionarios`),
  KEY `fk_dispositivo_has_funcionario_funcionario1_idx` (`idfuncionarios`),
  KEY `fk_dispositivo_has_funcionario_dispositivo1_idx` (`iddispositivos`),
  CONSTRAINT `fk_dispositivo_has_funcionario_dispositivo1` FOREIGN KEY (`iddispositivos`) REFERENCES `dispositivo` (`iddispositivos`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_dispositivo_has_funcionario_funcionario1` FOREIGN KEY (`idfuncionarios`) REFERENCES `funcionario` (`idfuncionarios`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `logs_dispositivos`
--

LOCK TABLES `logs_dispositivos` WRITE;
/*!40000 ALTER TABLE `logs_dispositivos` DISABLE KEYS */;
/*!40000 ALTER TABLE `logs_dispositivos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `registro_infracao`
--

DROP TABLE IF EXISTS `registro_infracao`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `registro_infracao` (
  `idregistro` int(11) NOT NULL AUTO_INCREMENT,
  `dados` varchar(45) DEFAULT NULL,
  `iddispositivo` int(11) NOT NULL,
  `cnh_condutor` int(11) DEFAULT NULL,
  `placa_veiculo` varchar(45) DEFAULT NULL,
  `data_infracao` date DEFAULT NULL,
  `horario_infracao` time DEFAULT NULL,
  PRIMARY KEY (`idregistro`),
  KEY `fk_registro_infracao_dispositivo1_idx` (`iddispositivo`),
  CONSTRAINT `fk_registro_infracao_dispositivo1` FOREIGN KEY (`iddispositivo`) REFERENCES `dispositivo` (`iddispositivos`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `registro_infracao`
--

LOCK TABLES `registro_infracao` WRITE;
/*!40000 ALTER TABLE `registro_infracao` DISABLE KEYS */;
/*!40000 ALTER TABLE `registro_infracao` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-09 20:26:29
