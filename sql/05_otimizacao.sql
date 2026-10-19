-- ============================================================
-- ARTEFATO B4: OTIMIZAÇÃO DE CONSULTAS (EXPLAIN + ÍNDICES + MEDIÇÃO)
-- Sistema de Gestão de Assistência Técnica e Manutenção (SGATM)
-- SGBD: MySQL 8.0.18+ (usa EXPLAIN ANALYZE)
--
-- Pré-requisito: ter executado 01_ddl.sql, 02_carga.sql e 04a_massa_volume.sql.
-- Os testes rodam no banco sgatm_perf (massa em volume). No final, os
-- mesmos índices são aplicados ao banco oficial sgatm_db.
--
-- Consultas críticas escolhidas (de 03_consultas.sql):
--   C08 - clientes com mais de 1 OS         (junção ORDEM_SERVICO x CLIENTE)
--   C09 - OS finalizadas por técnico        (filtro por status + junção por técnico)
--   C14 - tempo médio de resolução (SLA)    (agregações sobre HISTORICO_STATUS_OS)
--
-- Como ler o EXPLAIN:
--   type  : ALL = varredura completa da tabela; ref/range/index = usa índice
--   key   : índice efetivamente usado (NULL = nenhum)
--   rows  : estimativa de linhas lidas      Extra: "Using index" = índice cobre a consulta
-- Como medir: EXPLAIN ANALYZE executa a consulta e mostra "actual time" (ms).
-- ============================================================

USE sgatm_perf;
ANALYZE TABLE ORDEM_SERVICO, HISTORICO_STATUS_OS;

-- ------------------------------------------------------------
-- Índices que JÁ existiam no DDL (para comparação)
-- ------------------------------------------------------------
SHOW INDEX FROM ORDEM_SERVICO;
SHOW INDEX FROM HISTORICO_STATUS_OS;

-- ============================================================
-- PARTE 1 - ANTES DOS ÍNDICES
-- ============================================================

-- ---- C08: Clientes com mais de 1 OS (consulta 08 do 03_consultas.sql) ----
EXPLAIN
SELECT 
    c.id_cliente, 
    p.nome AS nome_cliente, 
    COUNT(os.id_os) AS total_os
FROM CLIENTE c
INNER JOIN PESSOA p ON c.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON c.id_cliente = os.id_cliente
GROUP BY c.id_cliente, p.nome
HAVING COUNT(os.id_os) > 1
ORDER BY total_os DESC;

EXPLAIN ANALYZE
SELECT 
    c.id_cliente, 
    p.nome AS nome_cliente, 
    COUNT(os.id_os) AS total_os
FROM CLIENTE c
INNER JOIN PESSOA p ON c.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON c.id_cliente = os.id_cliente
GROUP BY c.id_cliente, p.nome
HAVING COUNT(os.id_os) > 1
ORDER BY total_os DESC;

-- ---- C09: OS finalizadas por técnico (consulta 09) ----
EXPLAIN
SELECT 
    f.id_funcionario AS id_tecnico, 
    p.nome AS nome_tecnico, 
    COUNT(os.id_os) AS total_os_finalizadas
FROM FUNCIONARIO f
INNER JOIN PESSOA p ON f.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON f.id_funcionario = os.id_tecnico
WHERE os.status IN ('Concluido', 'Entregue')
GROUP BY f.id_funcionario, p.nome
ORDER BY total_os_finalizadas DESC;

EXPLAIN ANALYZE
SELECT 
    f.id_funcionario AS id_tecnico, 
    p.nome AS nome_tecnico, 
    COUNT(os.id_os) AS total_os_finalizadas
FROM FUNCIONARIO f
INNER JOIN PESSOA p ON f.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON f.id_funcionario = os.id_tecnico
WHERE os.status IN ('Concluido', 'Entregue')
GROUP BY f.id_funcionario, p.nome
ORDER BY total_os_finalizadas DESC;

-- ---- C14: Tempo médio de resolução por técnico / SLA (consulta 14) ----
EXPLAIN
SELECT 
    f.id_funcionario AS id_tecnico,
    p.nome AS nome_tecnico,
    COUNT(DISTINCT os.id_os) AS total_os_atendidas,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, h_inicio.data_inicio, h_fim.data_fim)), 1) AS tempo_medio_resolucao_horas
FROM FUNCIONARIO f
INNER JOIN PESSOA p ON f.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON f.id_funcionario = os.id_tecnico
INNER JOIN (
    SELECT id_os, MIN(data_hora) AS data_inicio
    FROM HISTORICO_STATUS_OS
    GROUP BY id_os
) h_inicio ON os.id_os = h_inicio.id_os
INNER JOIN (
    SELECT id_os, MAX(data_hora) AS data_fim
    FROM HISTORICO_STATUS_OS
    WHERE status_novo IN ('Concluido', 'Entregue')
    GROUP BY id_os
) h_fim ON os.id_os = h_fim.id_os
GROUP BY f.id_funcionario, p.nome
ORDER BY tempo_medio_resolucao_horas ASC;

EXPLAIN ANALYZE
SELECT 
    f.id_funcionario AS id_tecnico,
    p.nome AS nome_tecnico,
    COUNT(DISTINCT os.id_os) AS total_os_atendidas,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, h_inicio.data_inicio, h_fim.data_fim)), 1) AS tempo_medio_resolucao_horas
FROM FUNCIONARIO f
INNER JOIN PESSOA p ON f.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON f.id_funcionario = os.id_tecnico
INNER JOIN (
    SELECT id_os, MIN(data_hora) AS data_inicio
    FROM HISTORICO_STATUS_OS
    GROUP BY id_os
) h_inicio ON os.id_os = h_inicio.id_os
INNER JOIN (
    SELECT id_os, MAX(data_hora) AS data_fim
    FROM HISTORICO_STATUS_OS
    WHERE status_novo IN ('Concluido', 'Entregue')
    GROUP BY id_os
) h_fim ON os.id_os = h_fim.id_os
GROUP BY f.id_funcionario, p.nome
ORDER BY tempo_medio_resolucao_horas ASC;

-- ============================================================
-- PARTE 2 - CRIAÇÃO DOS ÍNDICES
-- ============================================================

-- C08: ORDEM_SERVICO não tinha índice começando por id_cliente (o único índice com
-- esse campo é (id_equipamento, id_cliente), que não serve para buscar por cliente).
CREATE INDEX idx_os_cliente ON ORDEM_SERVICO (id_cliente);

-- C09: índice composto (id_tecnico, status). Permite achar as OSs de cada técnico
-- já filtrando por status, sem ler a tabela (índice "cobre" a consulta).
CREATE INDEX idx_os_tecnico_status ON ORDEM_SERVICO (id_tecnico, status);

-- C14: índice composto (id_os, status_novo, data_hora). As duas subconsultas
-- (MIN e MAX de data_hora por OS) passam a ler só o índice, em vez da tabela inteira.
CREATE INDEX idx_hist_os_status_data ON HISTORICO_STATUS_OS (id_os, status_novo, data_hora);

-- Atualiza as estatísticas para o otimizador enxergar os novos índices
ANALYZE TABLE ORDEM_SERVICO, HISTORICO_STATUS_OS;

-- ============================================================
-- PARTE 3 - DEPOIS DOS ÍNDICES
-- ============================================================

-- ---- C08: Clientes com mais de 1 OS (consulta 08 do 03_consultas.sql) ----
EXPLAIN
SELECT 
    c.id_cliente, 
    p.nome AS nome_cliente, 
    COUNT(os.id_os) AS total_os
FROM CLIENTE c
INNER JOIN PESSOA p ON c.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON c.id_cliente = os.id_cliente
GROUP BY c.id_cliente, p.nome
HAVING COUNT(os.id_os) > 1
ORDER BY total_os DESC;

EXPLAIN ANALYZE
SELECT 
    c.id_cliente, 
    p.nome AS nome_cliente, 
    COUNT(os.id_os) AS total_os
FROM CLIENTE c
INNER JOIN PESSOA p ON c.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON c.id_cliente = os.id_cliente
GROUP BY c.id_cliente, p.nome
HAVING COUNT(os.id_os) > 1
ORDER BY total_os DESC;

-- ---- C09: OS finalizadas por técnico (consulta 09) ----
EXPLAIN
SELECT 
    f.id_funcionario AS id_tecnico, 
    p.nome AS nome_tecnico, 
    COUNT(os.id_os) AS total_os_finalizadas
FROM FUNCIONARIO f
INNER JOIN PESSOA p ON f.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON f.id_funcionario = os.id_tecnico
WHERE os.status IN ('Concluido', 'Entregue')
GROUP BY f.id_funcionario, p.nome
ORDER BY total_os_finalizadas DESC;

EXPLAIN ANALYZE
SELECT 
    f.id_funcionario AS id_tecnico, 
    p.nome AS nome_tecnico, 
    COUNT(os.id_os) AS total_os_finalizadas
FROM FUNCIONARIO f
INNER JOIN PESSOA p ON f.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON f.id_funcionario = os.id_tecnico
WHERE os.status IN ('Concluido', 'Entregue')
GROUP BY f.id_funcionario, p.nome
ORDER BY total_os_finalizadas DESC;

-- ---- C14: Tempo médio de resolução por técnico / SLA (consulta 14) ----
EXPLAIN
SELECT 
    f.id_funcionario AS id_tecnico,
    p.nome AS nome_tecnico,
    COUNT(DISTINCT os.id_os) AS total_os_atendidas,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, h_inicio.data_inicio, h_fim.data_fim)), 1) AS tempo_medio_resolucao_horas
FROM FUNCIONARIO f
INNER JOIN PESSOA p ON f.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON f.id_funcionario = os.id_tecnico
INNER JOIN (
    SELECT id_os, MIN(data_hora) AS data_inicio
    FROM HISTORICO_STATUS_OS
    GROUP BY id_os
) h_inicio ON os.id_os = h_inicio.id_os
INNER JOIN (
    SELECT id_os, MAX(data_hora) AS data_fim
    FROM HISTORICO_STATUS_OS
    WHERE status_novo IN ('Concluido', 'Entregue')
    GROUP BY id_os
) h_fim ON os.id_os = h_fim.id_os
GROUP BY f.id_funcionario, p.nome
ORDER BY tempo_medio_resolucao_horas ASC;

EXPLAIN ANALYZE
SELECT 
    f.id_funcionario AS id_tecnico,
    p.nome AS nome_tecnico,
    COUNT(DISTINCT os.id_os) AS total_os_atendidas,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, h_inicio.data_inicio, h_fim.data_fim)), 1) AS tempo_medio_resolucao_horas
FROM FUNCIONARIO f
INNER JOIN PESSOA p ON f.id_pessoa = p.id_pessoa
INNER JOIN ORDEM_SERVICO os ON f.id_funcionario = os.id_tecnico
INNER JOIN (
    SELECT id_os, MIN(data_hora) AS data_inicio
    FROM HISTORICO_STATUS_OS
    GROUP BY id_os
) h_inicio ON os.id_os = h_inicio.id_os
INNER JOIN (
    SELECT id_os, MAX(data_hora) AS data_fim
    FROM HISTORICO_STATUS_OS
    WHERE status_novo IN ('Concluido', 'Entregue')
    GROUP BY id_os
) h_fim ON os.id_os = h_fim.id_os
GROUP BY f.id_funcionario, p.nome
ORDER BY tempo_medio_resolucao_horas ASC;

-- ============================================================
-- PARTE 4 - APLICAR OS MESMOS ÍNDICES NO BANCO OFICIAL (sgatm_db)
-- ============================================================
USE sgatm_db;
CREATE INDEX idx_os_cliente          ON ORDEM_SERVICO (id_cliente);
CREATE INDEX idx_os_tecnico_status   ON ORDEM_SERVICO (id_tecnico, status);
CREATE INDEX idx_hist_os_status_data ON HISTORICO_STATUS_OS (id_os, status_novo, data_hora);
SHOW INDEX FROM ORDEM_SERVICO;
SHOW INDEX FROM HISTORICO_STATUS_OS;
