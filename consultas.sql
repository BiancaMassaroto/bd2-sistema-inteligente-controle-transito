-- 1. Quais bairros têm mais de N eventos de trânsito? (N = 5)
SELECT l.bairro, COUNT(*) AS total_eventos
FROM evento_trafego e
INNER JOIN local l ON e.idlocal = l.idlocal
GROUP BY l.bairro
HAVING COUNT(*) > 5
ORDER BY total_eventos DESC;

-- 2. Quais dispositivos estão inativos?
SELECT iddispositivos, tipo, idlocal
FROM dispositivos
WHERE ativo = 0;

-- 3. Quais foram as 10 infrações mais recentes?
SELECT idregistro, iddispositivo, placa_veiculo, data_infracao, horario_infracao
FROM registro_infracao
ORDER BY data_infracao DESC, horario_infracao DESC
LIMIT 10;

-- 4. Qual cidade tem mais ocorrências de infrações?
SELECT c.nome AS cidade, COUNT(*) AS total_infracoes
FROM registro_infracao r
INNER JOIN dispositivos d ON r.iddispositivo = d.iddispositivos
INNER JOIN local l        ON d.idlocal = l.idlocal
INNER JOIN cidade c       ON l.idcidade = c.idcidade
GROUP BY c.idcidade, c.nome
ORDER BY total_infracoes DESC
LIMIT 1;

-- 5. Em que horário do dia acontecem mais infrações?
SELECT HOUR(horario_infracao) AS hora, COUNT(*) AS total_infracoes
FROM registro_infracao
GROUP BY HOUR(horario_infracao)
ORDER BY total_infracoes DESC;

-- 6. Quantas infrações houve em cada mês?
SELECT YEAR(data_infracao) AS ano, MONTH(data_infracao) AS mes, COUNT(*) AS total_infracoes
FROM registro_infracao
GROUP BY YEAR(data_infracao), MONTH(data_infracao)
ORDER BY ano, mes;

-- 7. Qual dispositivo registrou o maior fluxo de veículos?
SELECT f.id_dispositivo, d.tipo, SUM(f.qtd_veiculos) AS total_veiculos
FROM fluxo_trafego f
INNER JOIN dispositivos d ON f.id_dispositivo = d.iddispositivos
GROUP BY f.id_dispositivo, d.tipo
ORDER BY total_veiculos DESC
LIMIT 1;

-- 8. Em quais horários a velocidade média cai abaixo de 20 km/h (congestionamento)?
SELECT HOUR(id_fluxo) AS hora, AVG(velocidade_media) AS velocidade_media_geral
FROM fluxo_trafego
GROUP BY HOUR(id_fluxo)
HAVING AVG(velocidade_media) < 20
ORDER BY velocidade_media_geral;

-- 9. Qual a velocidade média por bairro?
SELECT l.bairro, AVG(f.velocidade_media) AS velocidade_media
FROM fluxo_trafego f
INNER JOIN dispositivos d ON f.id_dispositivo = d.iddispositivos
INNER JOIN local l        ON d.idlocal = l.idlocal
GROUP BY l.bairro
ORDER BY velocidade_media;

-- 10. Quais são os tipos de evento mais frequentes?
SELECT tipo, COUNT(*) AS total
FROM evento_trafego
GROUP BY tipo
ORDER BY total DESC;

-- 11. Quais logs cada funcionário registrou, e em qual dispositivo?
SELECT lg.idlog, f.nome AS funcionario, d.tipo AS tipo_dispositivo,
       lg.descricao_log, lg.data_log, lg.horario_log
FROM logs_dispositivos lg
INNER JOIN funcionarios f ON lg.idfuncionarios = f.idfuncionarios
INNER JOIN dispositivos d ON lg.iddispositivos = d.iddispositivos
ORDER BY lg.data_log DESC, lg.horario_log DESC;

-- 12. Qual a velocidade mínima e máxima registrada em cada dispositivo?
SELECT f.id_dispositivo, d.tipo,
       MIN(f.velocidade_media) AS velocidade_minima,
       MAX(f.velocidade_media) AS velocidade_maxima
FROM fluxo_trafego f
INNER JOIN dispositivos d ON f.id_dispositivo = d.iddispositivos
GROUP BY f.id_dispositivo, d.tipo
ORDER BY velocidade_maxima DESC;

-- 13. Quais dispositivos têm velocidade média acima da média geral?
SELECT d.iddispositivos, d.tipo, AVG(f.velocidade_media) AS velocidade_media
FROM fluxo_trafego f
INNER JOIN dispositivos d ON f.id_dispositivo = d.iddispositivos
GROUP BY d.iddispositivos, d.tipo
HAVING AVG(f.velocidade_media) > (SELECT AVG(velocidade_media) FROM fluxo_trafego)
ORDER BY velocidade_media DESC;