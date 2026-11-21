-- ============================================================
-- ÍNDICES - Sistema Inteligente de Controle de Trânsito
-- Rode depois do ddl.sql e do dml.sql.
-- A análise e as justificativas estão em docs/indexacao.md.
-- Nomes de tabelas conforme o banco real (dispositivo e funcionario no singular).
-- ============================================================

-- USE nome_do_banco;  -- descomente e troque pelo nome do banco de vocês

-- 1. Infrações: consultas por data e hora (mais recentes, infrações por mês e por horário)
CREATE INDEX idx_infracao_data_hora
    ON registro_infracao (data_infracao, horario_infracao);

-- 2. Infrações: busca por placa de veículo (reincidência)
CREATE INDEX idx_infracao_placa
    ON registro_infracao (placa_veiculo);

-- 3. Dispositivo: contagem por tipo e filtro por situação (ativo/inativo)
CREATE INDEX idx_dispositivos_tipo_ativo
    ON dispositivo (tipo, ativo);

-- 4. Eventos de trânsito: tipos de evento mais frequentes
CREATE INDEX idx_evento_tipo
    ON evento_trafego (tipo);

-- 5. Local: agrupamento e busca por bairro
CREATE INDEX idx_local_bairro
    ON local (bairro);

-- 6. Fluxo de tráfego: agregações por dispositivo (índice de cobertura)
CREATE INDEX idx_fluxo_disp_velocidade
    ON fluxo_trafego (id_dispositivo, velocidade_media, qtd_veiculos);

-- ------------------------------------------------------------
-- Conferir os índices criados (apenas os nossos, que começam com idx_)
-- ------------------------------------------------------------
-- SELECT table_name, index_name
-- FROM information_schema.statistics
-- WHERE table_schema = DATABASE() AND index_name LIKE 'idx_%'
-- GROUP BY table_name, index_name;

-- ------------------------------------------------------------
-- Para desfazer (útil para repetir o teste "antes e depois" do EXPLAIN)
-- Se algum índice não existir, o MySQL dá erro; é só seguir para o próximo.
-- ------------------------------------------------------------
-- DROP INDEX idx_infracao_data_hora      ON registro_infracao;
-- DROP INDEX idx_infracao_placa          ON registro_infracao;
-- DROP INDEX idx_dispositivos_tipo_ativo ON dispositivo;
-- DROP INDEX idx_evento_tipo             ON evento_trafego;
-- DROP INDEX idx_local_bairro            ON local;
--
-- O índice da fluxo_trafego é usado pela chave estrangeira id_dispositivo.
-- Antes de apagá-lo, crie um índice simples na mesma coluna:
-- CREATE INDEX idx_fluxo_disp ON fluxo_trafego (id_dispositivo);
-- DROP INDEX idx_fluxo_disp_velocidade ON fluxo_trafego;
--
-- Alternativa que não mexe no banco: mostrar o "antes" ignorando o índice só na consulta:
-- EXPLAIN SELECT tipo, COUNT(*) FROM dispositivo IGNORE INDEX (idx_dispositivos_tipo_ativo) GROUP BY tipo;
