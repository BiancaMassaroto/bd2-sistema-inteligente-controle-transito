SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE SCHEMA IF NOT EXISTS `sistema_transito` DEFAULT CHARACTER SET utf8mb4 ;
USE `sistema_transito` ;

CREATE TABLE IF NOT EXISTS `estado` (
  `idestado` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(45) NULL,
  `sigla` VARCHAR(45) NULL,
  PRIMARY KEY (`idestado`)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `cidade` (
  `idcidade` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(45) NULL,
  `idestado` INT NOT NULL,
  PRIMARY KEY (`idcidade`),
  INDEX `fk_cidade_estado_idx` (`idestado` ASC),
  CONSTRAINT `fk_cidade_estado`
    FOREIGN KEY (`idestado`)
    REFERENCES `estado` (`idestado`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `local` (
  `idlocal` INT NOT NULL AUTO_INCREMENT,
  `logradouro` VARCHAR(45) NULL,
  `bairro` VARCHAR(45) NULL,
  `CEP` INT NULL,
  `idcidade` INT NOT NULL,
  PRIMARY KEY (`idlocal`),
  INDEX `fk_local_cidade1_idx` (`idcidade` ASC),
  CONSTRAINT `fk_local_cidade1`
    FOREIGN KEY (`idcidade`)
    REFERENCES `cidade` (`idcidade`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `evento_trafego` (
  `id_evento` INT NOT NULL AUTO_INCREMENT,
  `descricao` VARCHAR(280) NULL,
  `tipo` VARCHAR(50) NULL,
  `duracao` VARCHAR(45) NULL,
  `timestamp` DATETIME NULL,
  `idlocal` INT NOT NULL,
  PRIMARY KEY (`id_evento`),
  INDEX `fk_evento_trafego_local1_idx` (`idlocal` ASC),
  CONSTRAINT `fk_evento_trafego_local1`
    FOREIGN KEY (`idlocal`)
    REFERENCES `local` (`idlocal`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `funcionario` (
  `idfuncionarios` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(45) NULL,
  PRIMARY KEY (`idfuncionarios`)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `dispositivo` (
  `iddispositivos` INT NOT NULL AUTO_INCREMENT,
  `tipo` VARCHAR(45) NULL,
  `ativo` TINYINT NULL,
  `idlogs` INT NULL,
  `idlocal` INT NOT NULL,
  PRIMARY KEY (`iddispositivos`),
  INDEX `fk_dispositivos_local1_idx` (`idlocal` ASC),
  CONSTRAINT `fk_dispositivos_local1`
    FOREIGN KEY (`idlocal`)
    REFERENCES `local` (`idlocal`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `dispositivos_incidentes` (
  `iddispositivos` INT NOT NULL,
  `idincidentes` INT NOT NULL,
  PRIMARY KEY (`iddispositivos`, `idincidentes`),
  INDEX `fk_dispositivo_has_evento_trafego_evento_trafego1_idx` (`idincidentes` ASC),
  INDEX `fk_dispositivo_has_evento_trafego_dispositivo1_idx` (`iddispositivos` ASC),
  CONSTRAINT `fk_dispositivo_has_evento_trafego_dispositivo1`
    FOREIGN KEY (`iddispositivos`)
    REFERENCES `dispositivo` (`iddispositivos`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_dispositivo_has_evento_trafego_evento_trafego1`
    FOREIGN KEY (`idincidentes`)
    REFERENCES `evento_trafego` (`id_evento`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `ciclo_semaforo` (
  `iddispositivos` INT NOT NULL,
  `verde` INT NULL,
  `amarelo` INT NULL,
  `vermelho` INT NULL,
  `timestamp` DATETIME NULL,
  PRIMARY KEY (`iddispositivos`),
  CONSTRAINT `fk_ciclo_semaforo_dispositivo1`
    FOREIGN KEY (`iddispositivos`)
    REFERENCES `dispositivo` (`iddispositivos`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `fluxo_trafego` (
  `id_fluxo` DATETIME NOT NULL,
  `qtd_veiculos` INT NULL,
  `velocidade_media` DECIMAL(10,2) NULL,
  `sentido` VARCHAR(45) NULL,
  `id_dispositivo` INT NOT NULL,
  PRIMARY KEY (`id_fluxo`),
  INDEX `fk_fluxo_trafego_dispositivo1_idx` (`id_dispositivo` ASC),
  CONSTRAINT `fk_fluxo_trafego_dispositivo1`
    FOREIGN KEY (`id_dispositivo`)
    REFERENCES `dispositivo` (`iddispositivos`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `registro_infracao` (
  `idregistro` INT NOT NULL AUTO_INCREMENT,
  `dados` VARCHAR(45) NULL,
  `iddispositivo` INT NOT NULL,
  `cnh_condutor` INT NULL,
  `placa_veiculo` VARCHAR(45) NULL,
  `data_infracao` DATE NULL,
  `horario_infracao` TIME NULL,
  PRIMARY KEY (`idregistro`),
  INDEX `fk_registro_infracao_dispositivo1_idx` (`iddispositivo` ASC),
  CONSTRAINT `fk_registro_infracao_dispositivo1`
    FOREIGN KEY (`iddispositivo`)
    REFERENCES `dispositivo` (`iddispositivos`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `logs_dispositivos` (
  `iddispositivos` INT NOT NULL,
  `idfuncionarios` INT NOT NULL,
  `idlogs_dispositivoscol` INT NOT NULL,
  `descricao_log` VARCHAR(45) NULL,
  `data_log` DATE NULL,
  `horario_log` TIME NULL,
  PRIMARY KEY (`idlogs_dispositivoscol`, `iddispositivos`, `idfuncionarios`),
  INDEX `fk_dispositivo_has_funcionario_funcionario1_idx` (`idfuncionarios` ASC),
  INDEX `fk_dispositivo_has_funcionario_dispositivo1_idx` (`iddispositivos` ASC),
  CONSTRAINT `fk_dispositivo_has_funcionario_dispositivo1`
    FOREIGN KEY (`iddispositivos`)
    REFERENCES `dispositivo` (`iddispositivos`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_dispositivo_has_funcionario_funcionario1`
    FOREIGN KEY (`idfuncionarios`)
    REFERENCES `funcionario` (`idfuncionarios`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
