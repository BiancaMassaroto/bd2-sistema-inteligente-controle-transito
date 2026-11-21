-- ============================================================
-- VIEWS - Sistema Inteligente de Controle de Trânsito
-- Rode depois do ddl.sql e do dml.sql (as views precisam de dados para mostrar resultado).
-- Nomes de tabelas conforme o banco real (dispositivo e funcionario no singular).
-- ============================================================

-- USE nome_do_banco;  -- descomente e troque pelo nome do banco de vocês

-- ------------------------------------------------------------
-- 1. vw_dispositivos_localizacao
-- Finalidade: consolidar em um só lugar cada dispositivo com seu local,
-- cidade e estado. Evita repetir um JOIN de 4 tabelas em várias consultas.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_dispositivos_localizacao AS
SELECT d.iddispositivos,
       d.tipo,
       d.ativo,
       l.logradouro,
       l.bairro,
       l.CEP,
       c.nome  AS cidade,
       e.sigla AS estado
FROM dispositivo d
INNER JOIN local l  ON d.idlocal = l.idlocal
INNER JOIN cidade c ON l.idcidade = c.idcidade
INNER JOIN estado e ON c.idestado = e.idestado;

-- ------------------------------------------------------------
-- 2. vw_infracoes_por_dispositivo
-- Finalidade: relatório de quantas infrações cada dispositivo registrou.
-- Usa LEFT JOIN para que dispositivos sem nenhuma infração também apareçam (total 0).
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_infracoes_por_dispositivo AS
SELECT d.iddispositivos,
       d.tipo,
       l.bairro,
       COUNT(r.idregistro) AS total_infracoes
FROM dispositivo d
INNER JOIN local l ON d.idlocal = l.idlocal
LEFT JOIN registro_infracao r ON r.iddispositivo = d.iddispositivos
GROUP BY d.iddispositivos, d.tipo, l.bairro;

-- ------------------------------------------------------------
-- 3. vw_resumo_fluxo_dispositivo
-- Finalidade: resumo do fluxo de tráfego por dispositivo (total de veículos
-- e velocidades média, mínima e máxima). Simplifica relatórios de desempenho das vias.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_resumo_fluxo_dispositivo AS
SELECT f.id_dispositivo AS iddispositivos,
       d.tipo,
       SUM(f.qtd_veiculos)     AS total_veiculos,
       AVG(f.velocidade_media) AS velocidade_media,
       MIN(f.velocidade_media) AS velocidade_minima,
       MAX(f.velocidade_media) AS velocidade_maxima
FROM fluxo_trafego f
INNER JOIN dispositivo d ON f.id_dispositivo = d.iddispositivos
GROUP BY f.id_dispositivo, d.tipo;

-- ------------------------------------------------------------
-- 4. vw_logs_detalhados
-- Finalidade: consulta frequente de auditoria. Mostra cada log com o nome do
-- funcionário que o registrou e o dispositivo envolvido, sem precisar de JOIN manual.
-- Obs.: a tabela logs_dispositivos do banco real ainda não tem a coluna descricao_log.
-- Se ela for adicionada, inclua lg.descricao_log no SELECT.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_logs_detalhados AS
SELECT lg.idlogs_dispositivoscol AS idlog,
       lg.data_log,
       lg.horario_log,
       f.nome AS funcionario,
       d.iddispositivos,
       d.tipo AS tipo_dispositivo
FROM logs_dispositivos lg
INNER JOIN funcionario f ON lg.idfuncionarios = f.idfuncionarios
INNER JOIN dispositivo d ON lg.iddispositivos = d.iddispositivos;

-- ------------------------------------------------------------
-- 5. vw_eventos_por_bairro
-- Finalidade: relatório de ocorrências de trânsito por cidade, bairro e tipo
-- de evento. Ajuda a identificar as áreas mais problemáticas.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_eventos_por_bairro AS
SELECT c.nome AS cidade,
       l.bairro,
       ev.tipo,
       COUNT(*) AS total_eventos
FROM evento_trafego ev
INNER JOIN local l  ON ev.idlocal = l.idlocal
INNER JOIN cidade c ON l.idcidade = c.idcidade
GROUP BY c.nome, l.bairro, ev.tipo;

-- ------------------------------------------------------------
-- Testes (execute para conferir se cada view retorna dados)
-- ------------------------------------------------------------
-- SELECT * FROM vw_dispositivos_localizacao;
-- SELECT * FROM vw_infracoes_por_dispositivo ORDER BY total_infracoes DESC;
-- SELECT * FROM vw_resumo_fluxo_dispositivo;
-- SELECT * FROM vw_logs_detalhados ORDER BY data_log DESC, horario_log DESC;
-- SELECT * FROM vw_eventos_por_bairro ORDER BY total_eventos DESC;
