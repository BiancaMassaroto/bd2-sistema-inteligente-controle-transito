SET NAMES utf8mb4;
USE sistema_transito;

-- TRIGGER 1: AUDITORIA (UPDATE)
-- Quando tipo, ativo ou idlocal de um dispositivo mudam, insere uma linha
-- em logs_dispositivos (dispositivo, funcionário, data e hora).
-- O funcionário responsável é informado pela variável de sessão
-- @id_funcionario, definida antes da alteração:
--     SET @id_funcionario = 10;
-- Sem a variável, a alteração acontece normalmente, mas nada é registrado.

DELIMITER $$
CREATE TRIGGER trg_dispositivo_auditoria_update
AFTER UPDATE ON dispositivo
FOR EACH ROW
BEGIN
  DECLARE v_proximo_log INT DEFAULT 1;

  IF @id_funcionario IS NOT NULL
     AND NOT (OLD.ativo   <=> NEW.ativo
          AND OLD.tipo    <=> NEW.tipo
          AND OLD.idlocal <=> NEW.idlocal) THEN

    SELECT COALESCE(MAX(idlogs_dispositivoscol), 0) + 1
      INTO v_proximo_log
      FROM logs_dispositivos;

    INSERT INTO logs_dispositivos
      (iddispositivos, idfuncionarios, idlogs_dispositivoscol, data_log, horario_log)
    VALUES
      (NEW.iddispositivos, @id_funcionario, v_proximo_log, CURDATE(), CURTIME());
  END IF;
END$$
DELIMITER ;

-- TRIGGER 2: VALIDAÇÃO / REGRA DE NEGÓCIO (INSERT)
-- Antes de gravar um ciclo semafórico:
-- 1)o dispositivo precisa ser do tipo 'Semáforo';
-- 2)verde entre 10 e 60 s, amarelo entre 3 e 5 s, vermelho entre 30 e 90 s.

DELIMITER $$
CREATE TRIGGER trg_ciclo_semaforo_validacao_insert
BEFORE INSERT ON ciclo_semaforo
FOR EACH ROW
BEGIN
  DECLARE v_tipo VARCHAR(45) DEFAULT NULL;

  SELECT tipo INTO v_tipo
    FROM dispositivo
   WHERE iddispositivos = NEW.iddispositivos;

  IF v_tipo IS NULL OR v_tipo <> 'Semáforo' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ciclo semaforico so pode ser cadastrado para dispositivos do tipo Semaforo.';
  END IF;

  IF NEW.verde IS NULL OR NEW.verde NOT BETWEEN 10 AND 60 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Tempo do verde invalido: deve estar entre 10 e 60 segundos.';
  END IF;

  IF NEW.amarelo IS NULL OR NEW.amarelo NOT BETWEEN 3 AND 5 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Tempo do amarelo invalido: deve estar entre 3 e 5 segundos.';
  END IF;

  IF NEW.vermelho IS NULL OR NEW.vermelho NOT BETWEEN 30 AND 90 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Tempo do vermelho invalido: deve estar entre 30 e 90 segundos.';
  END IF;
END$$
DELIMITER ;

-- TRIGGER 3 - INTEGRIDADE DO HISTÓRICO (DELETE)
-- Sem uma tabela de histórico, a forma de preservar os dados é impedir a
-- exclusão: registros de infração não podem ser apagados.

DELIMITER $$
CREATE TRIGGER trg_registro_infracao_protege_delete
BEFORE DELETE ON registro_infracao
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Registros de infracao nao podem ser excluidos.';
END$$
DELIMITER ;

-- TESTES

-- Teste 1: auditoria no UPDATE (desfeito com ROLLBACK)
-- SET @id_funcionario = 1;
-- START TRANSACTION;
--   UPDATE dispositivo SET ativo = 1 - ativo WHERE iddispositivos = 1;
--   SELECT * FROM logs_dispositivos ORDER BY idlogs_dispositivoscol DESC LIMIT 1;
-- ROLLBACK;

-- Teste 2: validação no INSERT (os dois comandos devem dar ERRO)
-- 1) dispositivo 1 é Câmera, não Semáforo:
-- INSERT INTO ciclo_semaforo (iddispositivos, verde, amarelo, vermelho) VALUES (1, 30, 4, 60);
-- 2) dispositivo 3 é Semáforo, mas o verde está fora da faixa:
-- INSERT INTO ciclo_semaforo (iddispositivos, verde, amarelo, vermelho) VALUES (3, 99, 4, 60);

-- Teste 3: proteção no DELETE (deve dar ERRO)
-- DELETE FROM registro_infracao WHERE idregistro = 1;
-- Para listar os triggers criados:
-- SHOW TRIGGERS FROM sistema_transito;
