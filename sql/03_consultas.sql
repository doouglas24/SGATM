-- ============================================================
-- ARTEFATO A8: SCRIPT DE CONSULTAS DE VERIFICAÇÃO (SGATM)
-- Sistema de Gestão de Assistência Técnica e Manutenção
-- SGBD: MySQL 8.0
-- ============================================================

USE sgatm_db;

-- ============================================================
-- CATEGORIA 1: CONSULTAS BÁSICAS (5 CONSULTAS)
-- Recursos utilizados: Projeção, seleção com WHERE, ordenação,
-- LIKE, BETWEEN, IN e tratamento de NULL.
-- ============================================================

-- ------------------------------------------------------------
-- CONSULTA 01 (Básica)
-- Pergunta de Negócio: Listar o nome, e-mail e telefone de todas
-- as pessoas cadastradas cujo e-mail pertença ao domínio 'email.com',
-- ordenadas alfabeticamente pelo nome.
-- ------------------------------------------------------------
SELECT nome, email, telefone
FROM PESSOA
WHERE email LIKE '%@email.com'
ORDER BY nome ASC;

-- ------------------------------------------------------------
-- CONSULTA 02 (Básica)
-- Pergunta de Negócio: Listar os equipamentos que possuem número
-- de série informado (não nulo) e cujo tipo seja 'Smartphone' ou 'Notebook'.
-- ------------------------------------------------------------
SELECT id_equipamento, tipo_aparelho, marca, modelo, numero_serie
FROM EQUIPAMENTO
WHERE numero_serie IS NOT NULL
  AND tipo_aparelho IN ('Smartphone', 'Notebook')
ORDER BY marca, modelo;

-- ------------------------------------------------------------
-- CONSULTA 03 (Básica)
-- Pergunta de Negócio: Listar as peças em estoque cujo preço de venda
-- esteja na faixa entre R$ 50,00 e R$ 300,00, ordenadas do menor para o maior preço.
-- ------------------------------------------------------------
SELECT id_peca, descricao_peca, preco_custo, preco_venda, qtd_estoque
FROM PECA
WHERE preco_venda BETWEEN 50.00 AND 300.00
ORDER BY preco_venda ASC;

-- ------------------------------------------------------------
-- CONSULTA 04 (Básica)
-- Pergunta de Negócio: Listar os funcionários admitidos entre os anos
-- de 2022 e 2024 que possuem salário base estritamente maior que R$ 3.000,00.
-- ------------------------------------------------------------
SELECT id_funcionario, cargo, data_admissao, salario_base
FROM FUNCIONARIO
WHERE data_admissao BETWEEN '2022-01-01' AND '2024-12-31'
  AND salario_base > 3000.00
ORDER BY salario_base DESC;

-- ------------------------------------------------------------
-- CONSULTA 05 (Básica)
-- Pergunta de Negócio: Listar as Ordens de Serviço que não possuem técnico
-- responsável atribuído (id_tecnico IS NULL) ou que estão sem data prevista definida.
-- ------------------------------------------------------------
SELECT 
    id_os, 
    status, 
    defeito_relatado, 
    data_abertura, 
    id_tecnico, 
    data_prevista
FROM ORDEM_SERVICO
WHERE id_tecnico IS NULL OR data_prevista IS NULL
ORDER BY data_abertura DESC;


-- ============================================================
-- CATEGORIA 2: JUNÇÕES E AGREGAÇÃO (5 CONSULTAS)
-- Recursos utilizados: Junção de 3+ tabelas, LEFT JOIN, GROUP BY e HAVING.
-- ============================================================

-- ------------------------------------------------------------
-- CONSULTA 06 (Junção de 4 Tabelas)
-- Pergunta de Negócio: Listar todas as ordens de serviço cadastradas,
-- exibindo o ID da OS, o nome do cliente, o tipo/marca/modelo do equipamento e o status atual.
-- ------------------------------------------------------------
SELECT 
    os.id_os, 
    p.nome AS nome_cliente, 
    eq.tipo_aparelho, 
    eq.marca, 
    eq.modelo, 
    os.status, 
    os.data_abertura
FROM ORDEM_SERVICO os
INNER JOIN CLIENTE c ON os.id_cliente = c.id_cliente
INNER JOIN PESSOA p ON c.id_pessoa = p.id_pessoa
INNER JOIN EQUIPAMENTO eq ON os.id_equipamento = eq.id_equipamento
ORDER BY os.id_os ASC;

-- ------------------------------------------------------------
-- CONSULTA 07 (LEFT JOIN + Agregação)
-- Pergunta de Negócio: Listar todos os serviços do catálogo e a quantidade
-- total de vezes que cada serviço foi prestado em OSs, incluindo serviços que nunca foram utilizados.
-- ------------------------------------------------------------
SELECT 
    sc.id_servico, 
    sc.nome_servico, 
    sc.preco_base, 
    COALESCE(SUM(ps.quantidade), 0) AS total_unidades_prestadas
FROM SERVICO_CATALOGO sc
LEFT JOIN POSSUI_SERVICO ps ON sc.id_servico = ps.id_servico
GROUP BY sc.id_servico, sc.nome_servico, sc.preco_base
ORDER BY total_unidades_prestadas DESC;

-- ------------------------------------------------------------
-- CONSULTA 08 (GROUP BY + HAVING)
-- Pergunta de Negócio: Exibir os clientes (ID e nome) que possuem mais
-- de 1 Ordem de Serviço registrada no sistema.
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- CONSULTA 09 (Junção + Agregação)
-- Pergunta de Negócio: Exibir a quantidade de Ordens de Serviço finalizadas
-- (Concluido ou Entregue) por cada técnico da assistência, ordenando do maior para o menor.
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- CONSULTA 10 (LEFT JOIN + Agregação + Cálculo de Estoque)
-- Pergunta de Negócio: Listar todas as peças do catálogo, seu valor total
-- imobilizado em estoque (qtd_estoque * preco_custo) e o faturamento total bruto já gerado
-- com a venda dessa peça nas OSs.
-- ------------------------------------------------------------
SELECT 
    pe.id_peca, 
    pe.descricao_peca, 
    pe.qtd_estoque, 
    ROUND(pe.qtd_estoque * pe.preco_custo, 2) AS valor_estoque_custo, 
    ROUND(COALESCE(SUM(up.quantidade * up.preco_praticado), 0), 2) AS total_faturado_peca
FROM PECA pe
LEFT JOIN UTILIZA_PECA up ON pe.id_peca = up.id_peca
GROUP BY pe.id_peca, pe.descricao_peca, pe.qtd_estoque, pe.preco_custo
ORDER BY total_faturado_peca DESC;


-- ============================================================
-- CATEGORIA 3: CONSULTAS AVANÇADAS (5 CONSULTAS)
-- Recursos utilizados: Subconsulta correlacionada, EXISTS, Pergunta
-- de Negócio não trivial do domínio.
-- ============================================================

-- ------------------------------------------------------------
-- CONSULTA 11 (Subconsulta Correlacionada)
-- Pergunta de Negócio: Listar os serviços do catálogo cujo preço base cadastrado
-- é superior à média do preço efetivamente praticado para esse mesmo serviço nas ordens de serviço.
-- ------------------------------------------------------------
SELECT 
    sc.id_servico, 
    sc.nome_servico, 
    sc.preco_base
FROM SERVICO_CATALOGO sc
WHERE sc.preco_base > (
    SELECT AVG(ps.preco_praticado)
    FROM POSSUI_SERVICO ps
    WHERE ps.id_servico = sc.id_servico
)
ORDER BY sc.preco_base DESC;

-- ------------------------------------------------------------
-- CONSULTA 12 (Subconsulta com EXISTS)
-- Pergunta de Negócio: Listar os clientes que possuem pelo menos uma Ordem de Serviço
-- em que foi utilizada a peça 'Bateria iPhone 11' (utilizando a cláusula EXISTS).
-- ------------------------------------------------------------
SELECT 
    c.id_cliente, 
    p.nome AS nome_cliente, 
    p.email, 
    p.telefone
FROM CLIENTE c
INNER JOIN PESSOA p ON c.id_pessoa = p.id_pessoa
WHERE EXISTS (
    SELECT 1
    FROM ORDEM_SERVICO os
    INNER JOIN UTILIZA_PECA up ON os.id_os = up.id_os
    INNER JOIN PECA pe ON up.id_peca = pe.id_peca
    WHERE os.id_cliente = c.id_cliente
      AND pe.descricao_peca LIKE '%Bateria iPhone 11%'
)
ORDER BY p.nome ASC;

-- ------------------------------------------------------------
-- CONSULTA 13 (Pergunta de Negócio Não Trivial - Análise de Margem e Faturamento por OS)
-- Pergunta de Negócio: Para todas as Ordens de Serviço finalizadas (Concluido/Entregue),
-- calcular o faturamento bruto em serviços, faturamento em peças, o custo das peças utilizadas,
-- o lucro bruto gerado nas peças e o valor total cobrado do cliente (utilizando a VIEW de apoio vw_os_valor_total).
-- ------------------------------------------------------------
SELECT 
    os.id_os,
    p_cli.nome AS cliente,
    os.status,
    COALESCE(s_tot.total_servicos, 0) AS total_servicos,
    COALESCE(pec_tot.total_pecas, 0) AS total_pecas,
    COALESCE(pec_tot.custo_pecas, 0) AS custo_pecas,
    COALESCE(pec_tot.lucro_bruto_pecas, 0) AS lucro_bruto_pecas,
    v.valor_total AS valor_total_os
FROM ORDEM_SERVICO os
INNER JOIN CLIENTE c ON os.id_cliente = c.id_cliente
INNER JOIN PESSOA p_cli ON c.id_pessoa = p_cli.id_pessoa
INNER JOIN vw_os_valor_total v ON os.id_os = v.id_os
LEFT JOIN (
    SELECT id_os, SUM(quantidade * preco_praticado) AS total_servicos
    FROM POSSUI_SERVICO
    GROUP BY id_os
) s_tot ON os.id_os = s_tot.id_os
LEFT JOIN (
    SELECT 
        up.id_os, 
        SUM(up.quantidade * up.preco_praticado) AS total_pecas,
        SUM(up.quantidade * pe.preco_custo) AS custo_pecas,
        SUM(up.quantidade * up.preco_praticado) - SUM(up.quantidade * pe.preco_custo) AS lucro_bruto_pecas
    FROM UTILIZA_PECA up
    INNER JOIN PECA pe ON up.id_peca = pe.id_peca
    GROUP BY up.id_os
) pec_tot ON os.id_os = pec_tot.id_os
WHERE os.status IN ('Concluido', 'Entregue')
ORDER BY valor_total_os DESC;

-- ------------------------------------------------------------
-- CONSULTA 14 (Subconsultas de Auditoria / Métrica de SLA e Tempo de Resolução)
-- Pergunta de Negócio: Para cada técnico, calcular o tempo médio (em horas)
-- decorrido desde o primeiro registro no histórico de status de uma OS até a sua efetiva conclusão/entrega.
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- CONSULTA 15 (Gestão de Estoque Crítico em OSs em Andamento)
-- Pergunta de Negócio: Identificar quais peças estão com o estoque atual menor ou igual
-- à quantidade mínima de segurança e que possuem requisições ativas em OSs que ainda estão em andamento.
-- ------------------------------------------------------------
SELECT 
    pe.id_peca,
    pe.descricao_peca,
    pe.qtd_estoque,
    pe.qtd_minima,
    (pe.qtd_minima - pe.qtd_estoque) AS necessidade_reposicao,
    COUNT(DISTINCT up.id_os) AS qtd_os_em_andamento_usando
FROM PECA pe
INNER JOIN UTILIZA_PECA up ON pe.id_peca = up.id_peca
INNER JOIN ORDEM_SERVICO os ON up.id_os = os.id_os
WHERE pe.qtd_estoque <= pe.qtd_minima
  AND os.status IN ('Aberto', 'Em Diagnostico', 'Aguardando Peca', 'Em Execucao')
GROUP BY pe.id_peca, pe.descricao_peca, pe.qtd_estoque, pe.qtd_minima
ORDER BY necessidade_reposicao DESC;