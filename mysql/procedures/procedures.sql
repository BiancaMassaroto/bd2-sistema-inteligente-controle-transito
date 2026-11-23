-- ============================================================
-- STORED PROCEDURES - Sistema Inteligente de Controle de Trânsito
-- Banco: sistema_transito
--
-- Execução: mysql -u root -p < mysql/procedures/procedures.sql
-- No Workbench: abra o arquivo e execute o script inteiro (raio).
-- ============================================================

SET NAMES utf8mb4;
USE sistema_transito;

-- ------------------------------------------------------------
-- PROCEDURE 1 (com parâmetros de entrada)
-- Lista as infrações de um dispositivo em um período e informa o total.
-- Uso: CALL sp_infracoes_dispositivo(110, '2020-01-01', '2030-12-31');
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_infracoes_dispositivo;

DELIMITER $$
CREATE PROCEDURE sp_infracoes_dispositivo(
    IN p_dispositivo INT,
    IN p_inicio DATE,
    IN p_fim DATE
)
BEGIN
    SELECT COUNT(*) AS total_no_periodo
    FROM registro_infracao
    WHERE iddispositivo = p_dispositivo
      AND data_infracao BETWEEN p_inicio AND p_fim;

    SELECT data_infracao, horario_infracao, placa_veiculo
    FROM registro_infracao
    WHERE iddispositivo = p_dispositivo
      AND data_infracao BETWEEN p_inicio AND p_fim
    ORDER BY data_infracao DESC, horario_infracao DESC;
END$$
DELIMITER ;

-- ------------------------------------------------------------
-- PROCEDURE 2 (sem parâmetros)
-- Lista os dispositivos inativos com a localização, para a equipe de manutenção.
-- Uso: CALL sp_dispositivos_inativos();
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_dispositivos_inativos;

DELIMITER $$
CREATE PROCEDURE sp_dispositivos_inativos()
BEGIN
    SELECT d.iddispositivos AS id_dispositivo,
           d.tipo,
           l.logradouro,
           l.bairro,
           c.nome AS cidade
    FROM dispositivo d
    INNER JOIN local  l ON l.idlocal  = d.idlocal
    INNER JOIN cidade c ON c.idcidade = l.idcidade
    WHERE d.ativo = 0
    ORDER BY c.nome, l.bairro, d.iddispositivos;
END$$
DELIMITER ;

-- ------------------------------------------------------------
-- PROCEDURE 3 (com parâmetro de entrada e de saída)
-- Informa, para um bairro, o total de dispositivos, de infrações e de eventos.
-- Uso:
--   CALL sp_resumo_bairro('Copacabana', @disp, @infr, @ev);
--   SELECT @disp AS dispositivos, @infr AS infracoes, @ev AS eventos;
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_resumo_bairro;

DELIMITER $$
CREATE PROCEDURE sp_resumo_bairro(
    IN  p_bairro VARCHAR(45),
    OUT p_dispositivos INT,
    OUT p_infracoes INT,
    OUT p_eventos INT
)
BEGIN
    SELECT COUNT(*) INTO p_dispositivos
    FROM dispositivo d
    INNER JOIN local l ON l.idlocal = d.idlocal
    WHERE l.bairro = p_bairro;

    SELECT COUNT(*) INTO p_infracoes
    FROM registro_infracao r
    INNER JOIN dispositivo d ON d.iddispositivos = r.iddispositivo
    INNER JOIN local l       ON l.idlocal = d.idlocal
    WHERE l.bairro = p_bairro;

    SELECT COUNT(*) INTO p_eventos
    FROM evento_trafego e
    INNER JOIN local l ON l.idlocal = e.idlocal
    WHERE l.bairro = p_bairro;
END$$
DELIMITER ;
