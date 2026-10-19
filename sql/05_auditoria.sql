-- ============================================================
-- ARTEFATO B6: TABELA DE AUDITORIA E GATILHOS (TRIGGERS)
-- Sistema de Gestão de Assistência Técnica e Manutenção (SGATM)
-- SGBD: MySQL 8.0+
--
-- Objetivo: registrar automaticamente QUEM alterou, QUANDO e O QUE mudou
-- (valor anterior x valor novo) nos dados críticos do negócio:
--   * FUNCIONARIO      -> salário, cargo e supervisor (alteração/exclusão)
--   * PECA             -> preço de custo e de venda (alteração/exclusão)
--   * SERVICO_CATALOGO -> preço base (alteração)
--   * ORDEM_SERVICO    -> técnico, data prevista e diagnóstico (alteração)
--   * POSSUI_SERVICO / UTILIZA_PECA -> quantidade e preço praticado
--                         (alteração/exclusão) - protege o valor cobrado do cliente
--
-- Observações de projeto:
--   * A mudança de STATUS da OS já é registrada em HISTORICO_STATUS_OS (RN12),
--     por isso não é repetida aqui.
--   * qtd_estoque de PECA NÃO é auditada: ela muda a cada peça usada (triggers
--     RN18/RN19) e geraria ruído. Alterações de preço sim.
--   * AUDITORIA não tem FOREIGN KEY de propósito: o registro de auditoria de uma
--     linha excluída precisa continuar existindo.
--   * Como no histórico (RN13), a AUDITORIA é imutável: UPDATE/DELETE são bloqueados.
--
-- Pré-requisito: 01_ddl.sql (e, para os testes, 02_carga.sql).
-- ============================================================

USE sgatm_db;

-- ============================================================
-- 1. Tabela de auditoria
-- ============================================================
DROP TABLE IF EXISTS AUDITORIA;
CREATE TABLE AUDITORIA (
    id_auditoria   BIGINT AUTO_INCREMENT,
    tabela_afetada VARCHAR(50)  NOT NULL,
    operacao       ENUM('UPDATE','DELETE') NOT NULL,
    id_registro    VARCHAR(50)  NOT NULL,   -- chave do registro (composta: 'id_servico=3;id_os=7')
    campo_alterado VARCHAR(50)  NULL,       -- NULL em DELETE (o registro inteiro foi removido)
    valor_anterior VARCHAR(255) NULL,
    valor_novo     VARCHAR(255) NULL,
    usuario_banco  VARCHAR(100) NOT NULL,   -- conta MySQL que executou a alteração
    data_hora      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_auditoria PRIMARY KEY (id_auditoria)
) ENGINE=InnoDB;

CREATE INDEX idx_auditoria_registro ON AUDITORIA (tabela_afetada, id_registro);
CREATE INDEX idx_auditoria_data     ON AUDITORIA (data_hora);

-- ============================================================
-- 2. Procedimento auxiliar (evita repetir o INSERT em todo trigger)
-- ============================================================
DROP PROCEDURE IF EXISTS sp_registrar_auditoria;
DELIMITER $$
CREATE PROCEDURE sp_registrar_auditoria(
    IN p_tabela   VARCHAR(50),
    IN p_operacao VARCHAR(10),
    IN p_registro VARCHAR(50),
    IN p_campo    VARCHAR(50),
    IN p_antigo   VARCHAR(255),
    IN p_novo     VARCHAR(255)
)
BEGIN
    INSERT INTO AUDITORIA (tabela_afetada, operacao, id_registro, campo_alterado,
                           valor_anterior, valor_novo, usuario_banco)
    VALUES (p_tabela, p_operacao, p_registro, p_campo, p_antigo, p_novo, USER());
END$$
DELIMITER ;

-- ============================================================
-- 3. AUDITORIA imutável (mesma ideia da RN13 do histórico)
-- ============================================================
DELIMITER $$
CREATE TRIGGER trg_auditoria_imutavel_upd
BEFORE UPDATE ON AUDITORIA
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'AUDITORIA: registros de auditoria nao podem ser alterados.';
END$$

CREATE TRIGGER trg_auditoria_imutavel_del
BEFORE DELETE ON AUDITORIA
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'AUDITORIA: registros de auditoria nao podem ser excluidos.';
END$$
DELIMITER ;

-- ============================================================
-- 4. FUNCIONARIO: salário, cargo e supervisor
-- ============================================================
DELIMITER $$
CREATE TRIGGER trg_aud_funcionario_upd
AFTER UPDATE ON FUNCIONARIO
FOR EACH ROW
BEGIN
    IF NOT (OLD.salario_base <=> NEW.salario_base) THEN
        CALL sp_registrar_auditoria('FUNCIONARIO', 'UPDATE', OLD.id_funcionario,
                                    'salario_base', OLD.salario_base, NEW.salario_base);
    END IF;
    IF NOT (OLD.cargo <=> NEW.cargo) THEN
        CALL sp_registrar_auditoria('FUNCIONARIO', 'UPDATE', OLD.id_funcionario,
                                    'cargo', OLD.cargo, NEW.cargo);
    END IF;
    IF NOT (OLD.id_gerente <=> NEW.id_gerente) THEN
        CALL sp_registrar_auditoria('FUNCIONARIO', 'UPDATE', OLD.id_funcionario,
                                    'id_gerente', OLD.id_gerente, NEW.id_gerente);
    END IF;
END$$

CREATE TRIGGER trg_aud_funcionario_del
AFTER DELETE ON FUNCIONARIO
FOR EACH ROW
BEGIN
    CALL sp_registrar_auditoria('FUNCIONARIO', 'DELETE', OLD.id_funcionario, NULL,
        CONCAT('cargo=', OLD.cargo, '; salario_base=', OLD.salario_base,
               '; id_pessoa=', OLD.id_pessoa), NULL);
END$$
DELIMITER ;

-- ============================================================
-- 5. PECA: preço de custo e de venda
-- ============================================================
DELIMITER $$
CREATE TRIGGER trg_aud_peca_upd
AFTER UPDATE ON PECA
FOR EACH ROW
BEGIN
    IF NOT (OLD.preco_custo <=> NEW.preco_custo) THEN
        CALL sp_registrar_auditoria('PECA', 'UPDATE', OLD.id_peca,
                                    'preco_custo', OLD.preco_custo, NEW.preco_custo);
    END IF;
    IF NOT (OLD.preco_venda <=> NEW.preco_venda) THEN
        CALL sp_registrar_auditoria('PECA', 'UPDATE', OLD.id_peca,
                                    'preco_venda', OLD.preco_venda, NEW.preco_venda);
    END IF;
END$$

CREATE TRIGGER trg_aud_peca_del
AFTER DELETE ON PECA
FOR EACH ROW
BEGIN
    CALL sp_registrar_auditoria('PECA', 'DELETE', OLD.id_peca, NULL,
        CONCAT('descricao=', OLD.descricao_peca, '; preco_custo=', OLD.preco_custo,
               '; preco_venda=', OLD.preco_venda, '; qtd_estoque=', OLD.qtd_estoque), NULL);
END$$
DELIMITER ;

-- ============================================================
-- 6. SERVICO_CATALOGO: preço base
-- ============================================================
DELIMITER $$
CREATE TRIGGER trg_aud_servico_catalogo_upd
AFTER UPDATE ON SERVICO_CATALOGO
FOR EACH ROW
BEGIN
    IF NOT (OLD.preco_base <=> NEW.preco_base) THEN
        CALL sp_registrar_auditoria('SERVICO_CATALOGO', 'UPDATE', OLD.id_servico,
                                    'preco_base', OLD.preco_base, NEW.preco_base);
    END IF;
END$$
DELIMITER ;

-- ============================================================
-- 7. ORDEM_SERVICO: técnico responsável, data prevista e diagnóstico
--    (status fica no HISTORICO_STATUS_OS - RN12)
-- ============================================================
DELIMITER $$
CREATE TRIGGER trg_aud_os_upd
AFTER UPDATE ON ORDEM_SERVICO
FOR EACH ROW
BEGIN
    IF NOT (OLD.id_tecnico <=> NEW.id_tecnico) THEN
        CALL sp_registrar_auditoria('ORDEM_SERVICO', 'UPDATE', OLD.id_os,
                                    'id_tecnico', OLD.id_tecnico, NEW.id_tecnico);
    END IF;
    IF NOT (OLD.data_prevista <=> NEW.data_prevista) THEN
        CALL sp_registrar_auditoria('ORDEM_SERVICO', 'UPDATE', OLD.id_os,
                                    'data_prevista', OLD.data_prevista, NEW.data_prevista);
    END IF;
    IF NOT (OLD.diagnostico_tecnico <=> NEW.diagnostico_tecnico) THEN
        CALL sp_registrar_auditoria('ORDEM_SERVICO', 'UPDATE', OLD.id_os,
                                    'diagnostico_tecnico', OLD.diagnostico_tecnico, NEW.diagnostico_tecnico);
    END IF;
END$$
DELIMITER ;

-- ============================================================
-- 8. POSSUI_SERVICO: quantidade e preço praticado (valor cobrado do cliente)
-- ============================================================
DELIMITER $$
CREATE TRIGGER trg_aud_possui_servico_upd
AFTER UPDATE ON POSSUI_SERVICO
FOR EACH ROW
BEGIN
    DECLARE v_chave VARCHAR(50);
    SET v_chave = CONCAT('id_servico=', OLD.id_servico, ';id_os=', OLD.id_os);
    IF NOT (OLD.quantidade <=> NEW.quantidade) THEN
        CALL sp_registrar_auditoria('POSSUI_SERVICO', 'UPDATE', v_chave,
                                    'quantidade', OLD.quantidade, NEW.quantidade);
    END IF;
    IF NOT (OLD.preco_praticado <=> NEW.preco_praticado) THEN
        CALL sp_registrar_auditoria('POSSUI_SERVICO', 'UPDATE', v_chave,
                                    'preco_praticado', OLD.preco_praticado, NEW.preco_praticado);
    END IF;
END$$

CREATE TRIGGER trg_aud_possui_servico_del
AFTER DELETE ON POSSUI_SERVICO
FOR EACH ROW
BEGIN
    CALL sp_registrar_auditoria('POSSUI_SERVICO', 'DELETE',
        CONCAT('id_servico=', OLD.id_servico, ';id_os=', OLD.id_os), NULL,
        CONCAT('quantidade=', OLD.quantidade, '; preco_praticado=', OLD.preco_praticado), NULL);
END$$
DELIMITER ;

-- ============================================================
-- 9. UTILIZA_PECA: quantidade e preço praticado
-- ============================================================
DELIMITER $$
CREATE TRIGGER trg_aud_utiliza_peca_upd
AFTER UPDATE ON UTILIZA_PECA
FOR EACH ROW
BEGIN
    DECLARE v_chave VARCHAR(50);
    SET v_chave = CONCAT('id_peca=', OLD.id_peca, ';id_os=', OLD.id_os);
    IF NOT (OLD.quantidade <=> NEW.quantidade) THEN
        CALL sp_registrar_auditoria('UTILIZA_PECA', 'UPDATE', v_chave,
                                    'quantidade', OLD.quantidade, NEW.quantidade);
    END IF;
    IF NOT (OLD.preco_praticado <=> NEW.preco_praticado) THEN
        CALL sp_registrar_auditoria('UTILIZA_PECA', 'UPDATE', v_chave,
                                    'preco_praticado', OLD.preco_praticado, NEW.preco_praticado);
    END IF;
END$$

CREATE TRIGGER trg_aud_utiliza_peca_del
AFTER DELETE ON UTILIZA_PECA
FOR EACH ROW
BEGIN
    CALL sp_registrar_auditoria('UTILIZA_PECA', 'DELETE',
        CONCAT('id_peca=', OLD.id_peca, ';id_os=', OLD.id_os), NULL,
        CONCAT('quantidade=', OLD.quantidade, '; preco_praticado=', OLD.preco_praticado), NULL);
END$$
DELIMITER ;

-- ============================================================
-- 10. TESTES (rodam dentro de uma transação e terminam em ROLLBACK,
--     para não alterar os dados da carga; os SELECTs mostram o resultado)
-- ============================================================
START TRANSACTION;

-- T1: reajuste de salário do funcionário 3 (deve gerar 1 linha: salario_base)
UPDATE FUNCIONARIO SET salario_base = 2800.00 WHERE id_funcionario = 3;

-- T2: reajuste de preço da peça 1 (deve gerar 2 linhas: preco_custo e preco_venda)
UPDATE PECA SET preco_custo = preco_custo + 5, preco_venda = preco_venda + 10 WHERE id_peca = 1;

-- T3: alteração de preço base do serviço 1
UPDATE SERVICO_CATALOGO SET preco_base = preco_base + 20 WHERE id_servico = 1;

-- T4: troca do técnico da OS 21 (técnico 6 -> 7) e da data prevista
UPDATE ORDEM_SERVICO SET id_tecnico = 7, data_prevista = '2024-07-10' WHERE id_os = 21;

-- T5: alteração do preço praticado de um serviço numa OS (valor cobrado do cliente)
UPDATE POSSUI_SERVICO SET preco_praticado = preco_praticado - 10
 WHERE (id_servico, id_os) = (SELECT id_servico, id_os FROM (SELECT id_servico, id_os FROM POSSUI_SERVICO ORDER BY id_os LIMIT 1) t);

-- T6: UPDATE que NAO muda nenhum campo auditado não deve gerar registro
UPDATE FUNCIONARIO SET salario_base = salario_base WHERE id_funcionario = 4;

-- T7: remoção de peça usada numa OS (devolve estoque - RN19 - e deve ser auditada)
DELETE FROM UTILIZA_PECA ORDER BY id_os LIMIT 1;

SELECT id_auditoria, tabela_afetada, operacao, id_registro, campo_alterado,
       valor_anterior, valor_novo, usuario_banco, data_hora
FROM AUDITORIA
ORDER BY id_auditoria;

ROLLBACK;

-- T8: a auditoria é imutável (os dois comandos abaixo DEVEM falhar com erro).
-- Para testar, remova o '-- ' do início da linha e execute:
-- UPDATE AUDITORIA SET valor_novo = 'x' WHERE id_auditoria = 1;
-- DELETE FROM AUDITORIA WHERE id_auditoria = 1;

-- Consulta útil para o relatório: últimas alterações registradas
-- SELECT * FROM AUDITORIA ORDER BY data_hora DESC LIMIT 20;
