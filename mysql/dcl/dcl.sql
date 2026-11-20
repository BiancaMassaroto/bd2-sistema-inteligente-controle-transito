CREATE ROLE IF NOT EXISTS 'role_administrador', 'role_operador', 'role_analista';

-- perfil administrador: controle total sobre o schema (estrutura e dados).
GRANT ALL PRIVILEGES ON sistema_transito.* TO 'role_administrador';

-- perfil operador: cadastra e atualiza dispositivos, ciclos, eventos e fluxo. Não exclui dados e não altera a estrutura.
GRANT SELECT, INSERT, UPDATE ON sistema_transito.dispositivos TO 'role_operador';
GRANT SELECT, INSERT, UPDATE ON sistema_transito.ciclo_semaforo TO 'role_operador';
GRANT SELECT, INSERT, UPDATE ON sistema_transito.evento_trafego TO 'role_operador';
GRANT SELECT, INSERT, UPDATE ON sistema_transito.fluxo_trafego TO 'role_operador';
GRANT SELECT, INSERT, UPDATE ON sistema_transito.dispositivos_incidentes TO 'role_operador';

GRANT SELECT, INSERT ON sistema_transito.logs_dispositivos TO 'role_operador';
GRANT SELECT, INSERT ON sistema_transito.registro_infracao TO 'role_operador';

GRANT SELECT ON sistema_transito.estado TO 'role_operador';
GRANT SELECT ON sistema_transito.cidade TO 'role_operador';
GRANT SELECT ON sistema_transito.local TO 'role_operador';
GRANT SELECT ON sistema_transito.funcionarios TO 'role_operador';

-- perfil analista: lê os dados para relatórios, sem modificar nada. Dados pessoais sensíveis como CNH e placa ficam fora do acesso.
GRANT SELECT ON sistema_transito.estado TO 'role_analista';
GRANT SELECT ON sistema_transito.cidade TO 'role_analista';
GRANT SELECT ON sistema_transito.local TO 'role_analista';
GRANT SELECT ON sistema_transito.dispositivos TO 'role_analista';
GRANT SELECT ON sistema_transito.ciclo_semaforo TO 'role_analista';
GRANT SELECT ON sistema_transito.evento_trafego TO 'role_analista';
GRANT SELECT ON sistema_transito.fluxo_trafego TO 'role_analista';
GRANT SELECT ON sistema_transito.dispositivos_incidentes TO 'role_analista';
GRANT SELECT ON sistema_transito.logs_dispositivos TO 'role_analista';
GRANT SELECT ON sistema_transito.funcionarios TO 'role_analista';

GRANT SELECT (idregistro, dados, iddispositivo, data_infracao, horario_infracao)
    ON sistema_transito.registro_infracao TO 'role_analista';

-- usuarios
CREATE USER IF NOT EXISTS 'admin_transito'@'localhost' IDENTIFIED BY 'SenhaSegura1';
CREATE USER IF NOT EXISTS 'operador_transito'@'localhost' IDENTIFIED BY 'SenhaSegura2';
CREATE USER IF NOT EXISTS 'analista_transito'@'localhost' IDENTIFIED BY 'SenhaSegura3';

-- atribuição dos perfis
GRANT 'role_administrador' TO 'admin_transito'@'localhost';
GRANT 'role_operador' TO 'operador_transito'@'localhost';
GRANT 'role_analista' TO 'analista_transito'@'localhost';

-- exemplos de revoke
-- REVOKE UPDATE ON sistema_transito.ciclo_semaforo FROM 'role_operador';
-- REVOKE 'role_operador' FROM 'operador_transito'@'localhost';
-- DROP USER 'operador_transito'@'localhost';
