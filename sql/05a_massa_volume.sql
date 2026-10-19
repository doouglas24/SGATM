-- ============================================================
-- ARTEFATO B4 (apoio): MASSA DE DADOS EM VOLUME PARA TESTE DE DESEMPENHO
-- Sistema de Gestão de Assistência Técnica e Manutenção (SGATM)
-- SGBD: MySQL 8.0+
--
-- Por quê? A carga oficial (02_carga.sql) tem só 42 OSs. Com tão
-- poucas linhas o otimizador prefere varrer a tabela inteira e os
-- índices não mudam o resultado. Aqui criamos um banco separado
-- (sgatm_perf) com centenas de milhares de linhas, SOMENTE para
-- medir o ganho dos índices. O banco oficial (sgatm_db) não é alterado.
--
-- Ordem de execução: 01_ddl.sql -> 02_carga.sql -> 04a (este) -> 04_otimizacao.sql
-- Tempo aproximado: 30 a 60 segundos.
-- ============================================================

DROP DATABASE IF EXISTS sgatm_perf;
CREATE DATABASE sgatm_perf CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sgatm_perf;
SET NAMES 'utf8mb4';

-- Clona a ESTRUTURA do banco oficial (colunas, PK, UNIQUE, índices e CHECKs).
-- CREATE TABLE ... LIKE não copia triggers nem FKs: isso é desejado aqui,
-- pois a carga em volume não deve disparar triggers (estoque, histórico etc.).
CREATE TABLE PESSOA              LIKE sgatm_db.PESSOA;
CREATE TABLE CLIENTE             LIKE sgatm_db.CLIENTE;
CREATE TABLE FUNCIONARIO         LIKE sgatm_db.FUNCIONARIO;
CREATE TABLE EQUIPAMENTO         LIKE sgatm_db.EQUIPAMENTO;
CREATE TABLE ORDEM_SERVICO       LIKE sgatm_db.ORDEM_SERVICO;
CREATE TABLE HISTORICO_STATUS_OS LIKE sgatm_db.HISTORICO_STATUS_OS;
CREATE TABLE SERVICO_CATALOGO    LIKE sgatm_db.SERVICO_CATALOGO;
CREATE TABLE PECA                LIKE sgatm_db.PECA;
CREATE TABLE POSSUI_SERVICO      LIKE sgatm_db.POSSUI_SERVICO;
CREATE TABLE UTILIZA_PECA        LIKE sgatm_db.UTILIZA_PECA;

-- View de apoio (usada na consulta 13)
CREATE OR REPLACE VIEW vw_os_valor_total AS
SELECT os.id_os,
       COALESCE(serv.total_servicos, 0) + COALESCE(pec.total_pecas, 0) AS valor_total
FROM ORDEM_SERVICO os
LEFT JOIN (SELECT id_os, SUM(quantidade * preco_praticado) AS total_servicos
           FROM POSSUI_SERVICO GROUP BY id_os) serv ON serv.id_os = os.id_os
LEFT JOIN (SELECT id_os, SUM(quantidade * preco_praticado) AS total_pecas
           FROM UTILIZA_PECA GROUP BY id_os) pec ON pec.id_os = os.id_os;

SET SESSION cte_max_recursion_depth = 1000000;
SET UNIQUE_CHECKS = 0;

-- PESSOA: 10 funcionários + 60.000 clientes
INSERT INTO PESSOA (id_pessoa, cpf, nome, email, telefone)
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 60010)
SELECT i, LPAD(i, 11, '0'), CONCAT('Pessoa ', i),
       CONCAT('user', i, ELT(1 + MOD(i, 4), '@gmail.com', '@hotmail.com', '@outlook.com', '@sgatm.com.br')),
       CONCAT('(61) 9', LPAD(i, 8, '0'))
FROM n;

INSERT INTO FUNCIONARIO (id_funcionario, cargo, data_admissao, salario_base, id_gerente, id_pessoa) VALUES
(1, 'Gerente',   '2020-01-10', 9000, NULL, 1), (2, 'Gerente',   '2020-02-10', 9000, NULL, 2),
(3, 'Atendente', '2022-03-01', 2500, NULL, 3), (4, 'Atendente', '2023-03-01', 2500, NULL, 4),
(5, 'Atendente', '2024-03-01', 2500, NULL, 5),
(6, 'Tecnico',   '2022-05-01', 3500, 1, 6),    (7, 'Tecnico',   '2022-06-01', 3500, 1, 7),
(8, 'Tecnico',   '2023-05-01', 3600, 2, 8),    (9, 'Tecnico',   '2023-06-01', 3600, 2, 9),
(10,'Tecnico',   '2024-05-01', 3800, 1, 10);

INSERT INTO CLIENTE (id_cliente, data_cadastro, id_pessoa)
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 60000)
SELECT i, DATE_ADD('2020-01-01', INTERVAL MOD(i, 1800) DAY), i + 10 FROM n;

-- EQUIPAMENTO: 80.000 (1 por cliente + 20.000 extras)
INSERT INTO EQUIPAMENTO (id_equipamento, tipo_aparelho, marca, modelo, numero_serie, id_cliente)
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 80000)
SELECT i, ELT(1 + MOD(i, 5), 'Smartphone', 'Notebook', 'Console', 'Desktop', 'Tablet'),
       ELT(1 + MOD(i, 4), 'Apple', 'Samsung', 'Dell', 'Sony'), CONCAT('Modelo ', MOD(i, 50)),
       CONCAT('SN', LPAD(i, 10, '0')),
       IF(i <= 60000, i, (i - 60000) * 3)
FROM n;

INSERT INTO SERVICO_CATALOGO (id_servico, nome_servico, preco_base, tempo_estimado_min)
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 20)
SELECT i, CONCAT('Servico ', i), 50 + i * 10, 30 + i * 5 FROM n;

INSERT INTO PECA (id_peca, descricao_peca, preco_custo, preco_venda, qtd_estoque, qtd_minima)
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 200)
SELECT i, CONCAT('Peca ', i), 20 + i, 40 + i * 2, 1000000, IF(MOD(i, 10) = 0, 2000000, 5) FROM n;

-- ORDEM_SERVICO: 300.000 (5% sem técnico, ~7% sem data prevista, status variados)
INSERT INTO ORDEM_SERVICO (id_os, id_atendente, id_tecnico, id_cliente, id_equipamento,
                           data_abertura, data_prevista, defeito_relatado, diagnostico_tecnico, status)
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 300000)
SELECT i, 3 + MOD(i, 3),
       IF(MOD(i, 20) = 0, NULL, 6 + MOD(i, 5)),
       1 + MOD(i * 7, 60000), 1 + MOD(i * 7, 60000),
       DATE_ADD('2023-01-01 08:00:00', INTERVAL MOD(i * 37, 900000) MINUTE),
       IF(MOD(i, 15) = 0, NULL, DATE_ADD('2023-01-01', INTERVAL (MOD(i * 37, 900000) DIV 1440) + 3 DAY)),
       'Defeito relatado generico para teste de volume.',
       IF(MOD(i, 10) < 7, 'Diagnostico tecnico de teste.', NULL),
       ELT(1 + MOD(i, 10), 'Entregue', 'Entregue', 'Entregue', 'Entregue', 'Concluido', 'Concluido',
           'Em Execucao', 'Aguardando Peca', 'Em Diagnostico', 'Aberto')
FROM n;

-- HISTORICO_STATUS_OS: ~1,08 milhão de eventos coerentes com o status final de cada OS
INSERT INTO HISTORICO_STATUS_OS (id_os, data_hora, status_novo, id_funcionario)
SELECT id_os, data_abertura, 'Aberto', id_atendente FROM ORDEM_SERVICO;
INSERT INTO HISTORICO_STATUS_OS (id_os, data_hora, status_novo, id_funcionario)
SELECT id_os, DATE_ADD(data_abertura, INTERVAL 3 HOUR), 'Em Diagnostico', COALESCE(id_tecnico, id_atendente)
FROM ORDEM_SERVICO WHERE status <> 'Aberto';
INSERT INTO HISTORICO_STATUS_OS (id_os, data_hora, status_novo, id_funcionario)
SELECT id_os, DATE_ADD(data_abertura, INTERVAL 1 DAY), 'Em Execucao', COALESCE(id_tecnico, id_atendente)
FROM ORDEM_SERVICO WHERE status IN ('Em Execucao', 'Concluido', 'Entregue');
INSERT INTO HISTORICO_STATUS_OS (id_os, data_hora, status_novo, id_funcionario)
SELECT id_os, DATE_ADD(data_abertura, INTERVAL 2 DAY), 'Concluido', COALESCE(id_tecnico, id_atendente)
FROM ORDEM_SERVICO WHERE status IN ('Concluido', 'Entregue');
INSERT INTO HISTORICO_STATUS_OS (id_os, data_hora, status_novo, id_funcionario)
SELECT id_os, DATE_ADD(data_abertura, INTERVAL 3 DAY), 'Entregue', COALESCE(id_tecnico, id_atendente)
FROM ORDEM_SERVICO WHERE status = 'Entregue';

-- POSSUI_SERVICO (~450 mil) e UTILIZA_PECA (~400 mil)
INSERT INTO POSSUI_SERVICO (id_servico, id_os, quantidade, preco_praticado)
SELECT 1 + MOD(id_os, 20), id_os, 1, 50 + (1 + MOD(id_os, 20)) * 10 FROM ORDEM_SERVICO;
INSERT INTO POSSUI_SERVICO (id_servico, id_os, quantidade, preco_praticado)
SELECT 1 + MOD(id_os + 7, 20), id_os, 1 + MOD(id_os, 2), 55 + (1 + MOD(id_os + 7, 20)) * 10
FROM ORDEM_SERVICO WHERE MOD(id_os, 2) = 0;
INSERT INTO UTILIZA_PECA (id_peca, id_os, quantidade, preco_praticado)
SELECT 1 + MOD(id_os, 200), id_os, 1 + MOD(id_os, 3), 40 + (1 + MOD(id_os, 200)) * 2 FROM ORDEM_SERVICO;
INSERT INTO UTILIZA_PECA (id_peca, id_os, quantidade, preco_praticado)
SELECT 1 + MOD(id_os + 101, 200), id_os, 1, 40 + (1 + MOD(id_os + 101, 200)) * 2
FROM ORDEM_SERVICO WHERE MOD(id_os, 3) = 0;

SET UNIQUE_CHECKS = 1;

-- Atualiza as estatísticas do otimizador
ANALYZE TABLE PESSOA, CLIENTE, FUNCIONARIO, EQUIPAMENTO, ORDEM_SERVICO,
              HISTORICO_STATUS_OS, SERVICO_CATALOGO, PECA, POSSUI_SERVICO, UTILIZA_PECA;

-- Conferência do volume gerado
SELECT 'PESSOA' AS tabela, COUNT(*) AS linhas FROM PESSOA
UNION ALL SELECT 'EQUIPAMENTO', COUNT(*) FROM EQUIPAMENTO
UNION ALL SELECT 'ORDEM_SERVICO', COUNT(*) FROM ORDEM_SERVICO
UNION ALL SELECT 'HISTORICO_STATUS_OS', COUNT(*) FROM HISTORICO_STATUS_OS
UNION ALL SELECT 'POSSUI_SERVICO', COUNT(*) FROM POSSUI_SERVICO
UNION ALL SELECT 'UTILIZA_PECA', COUNT(*) FROM UTILIZA_PECA;
