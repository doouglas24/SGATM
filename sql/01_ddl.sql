-- ============================================================
-- ARTEFATO A6: SCRIPT DDL (DEFINIÇÃO DE DADOS - SGATM)
-- Sistema de Gestão de Assistência Técnica e Manutenção
-- SGBD: MySQL 8.0
-- ============================================================

DROP DATABASE IF EXISTS sgatm_db;
CREATE DATABASE sgatm_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE sgatm_db;

SET NAMES 'utf8mb4';

-- ============================================================
-- 1. Tabela PESSOA (Tabela Base) -- Implementa RN01
-- ============================================================
CREATE TABLE PESSOA (
    id_pessoa INT AUTO_INCREMENT,
    -- CORRIGIDO (H9): O Anexo A pedia 11 dígitos. VARCHAR(14) permitia máscara.
    cpf       VARCHAR(11)  NOT NULL,
    nome      VARCHAR(100) NOT NULL,
    email     VARCHAR(100) NOT NULL,
    telefone  VARCHAR(20)  NULL,
    CONSTRAINT pk_pessoa PRIMARY KEY (id_pessoa),
    CONSTRAINT uq_pessoa_cpf   UNIQUE (cpf),
    CONSTRAINT uq_pessoa_email UNIQUE (email),
    -- CORRIGIDO (H9): Validação básica de formato para impedir "abc" e "nao-e-email"
    CONSTRAINT ck_pessoa_cpf CHECK (LENGTH(cpf) = 11 AND cpf REGEXP '^[0-9]+$'),
    CONSTRAINT ck_pessoa_email CHECK (email LIKE '%@%')
) ENGINE=InnoDB;

-- ============================================================
-- 2. Tabela CLIENTE -- Implementa RN02
-- ============================================================
CREATE TABLE CLIENTE (
    id_cliente    INT AUTO_INCREMENT,
    data_cadastro DATE NOT NULL,
    id_pessoa     INT  NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_pessoa UNIQUE (id_pessoa),
    CONSTRAINT fk_cliente_pessoa FOREIGN KEY (id_pessoa)
        REFERENCES PESSOA (id_pessoa)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 3. Tabela FUNCIONARIO -- Implementa RN03, RN04
-- ============================================================
CREATE TABLE FUNCIONARIO (
    id_funcionario  INT AUTO_INCREMENT,
    cargo           ENUM('Gerente','Tecnico','Atendente') NOT NULL,
    data_admissao   DATE NOT NULL,
    salario_base    DECIMAL(10,2) NOT NULL,
    id_gerente      INT NULL,
    id_pessoa       INT NOT NULL,
    CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario),
    CONSTRAINT uq_funcionario_pessoa UNIQUE (id_pessoa),
    CONSTRAINT fk_funcionario_pessoa FOREIGN KEY (id_pessoa)
        REFERENCES PESSOA (id_pessoa)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_funcionario_gerente FOREIGN KEY (id_gerente)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_funcionario_salario CHECK (salario_base >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_funcionario_gerente ON FUNCIONARIO (id_gerente);

DELIMITER $$
CREATE TRIGGER trg_funcionario_rn04_ins
BEFORE INSERT ON FUNCIONARIO
FOR EACH ROW
BEGIN
    IF NEW.cargo = 'Tecnico' AND NEW.id_gerente IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN04: Tecnico deve possuir um Gerente associado como supervisor.';
    END IF;
    IF NEW.id_gerente IS NOT NULL AND NEW.id_gerente = NEW.id_funcionario THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Um funcionario nao pode ser seu proprio supervisor.';
    END IF;
    -- CORRIGIDO (H5): Validar se o supervisor informado é realmente um Gerente
    IF NEW.id_gerente IS NOT NULL AND (SELECT cargo FROM FUNCIONARIO WHERE id_funcionario = NEW.id_gerente) <> 'Gerente' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN04: O supervisor (id_gerente) deve ter o cargo de Gerente.';
    END IF;
END$$

CREATE TRIGGER trg_funcionario_rn04_upd
BEFORE UPDATE ON FUNCIONARIO
FOR EACH ROW
BEGIN
    IF NEW.cargo = 'Tecnico' AND NEW.id_gerente IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN04: Tecnico deve possuir um Gerente associado como supervisor.';
    END IF;
    IF NEW.id_gerente IS NOT NULL AND NEW.id_gerente = NEW.id_funcionario THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Um funcionario nao pode ser seu proprio supervisor.';
    END IF;
    -- CORRIGIDO (H5): Validar se o supervisor informado é realmente um Gerente
    IF NEW.id_gerente IS NOT NULL AND (SELECT cargo FROM FUNCIONARIO WHERE id_funcionario = NEW.id_gerente) <> 'Gerente' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN04: O supervisor (id_gerente) deve ter o cargo de Gerente.';
    END IF;
END$$
DELIMITER ;

-- ============================================================
-- 4. Tabela EQUIPAMENTO -- Implementa RN05, RN06
-- ============================================================
CREATE TABLE EQUIPAMENTO (
    id_equipamento INT AUTO_INCREMENT,
    tipo_aparelho  VARCHAR(50) NOT NULL,
    marca          VARCHAR(50) NOT NULL,
    modelo         VARCHAR(50) NOT NULL,
    numero_serie   VARCHAR(50) NULL,
    id_cliente     INT NOT NULL,
    CONSTRAINT pk_equipamento PRIMARY KEY (id_equipamento),
    CONSTRAINT uq_equipamento_numero_serie UNIQUE (numero_serie),
    -- CORRIGIDO (H3): Criada UNIQUE composta para permitir a amarração segura na OS
    CONSTRAINT uq_equipamento_cliente UNIQUE (id_equipamento, id_cliente),
    CONSTRAINT fk_equipamento_cliente FOREIGN KEY (id_cliente)
        REFERENCES CLIENTE (id_cliente)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_equipamento_cliente ON EQUIPAMENTO (id_cliente);

-- ============================================================
-- 5. Tabela ORDEM_SERVICO -- Implementa RN07, RN08, RN09, RN11
-- ============================================================
CREATE TABLE ORDEM_SERVICO (
    id_os               INT AUTO_INCREMENT,
    id_atendente        INT NOT NULL,
    id_tecnico          INT NULL,
    id_cliente          INT NOT NULL,
    id_equipamento      INT NOT NULL,
    data_abertura       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_prevista       DATE NULL,
    defeito_relatado    VARCHAR(500) NOT NULL,
    diagnostico_tecnico VARCHAR(500) NULL,
    status              ENUM('Aberto','Em Diagnostico','Aguardando Peca',
                              'Em Execucao','Concluido','Entregue','Cancelado')
                        NOT NULL DEFAULT 'Aberto',
    CONSTRAINT pk_ordem_servico PRIMARY KEY (id_os),
    CONSTRAINT fk_os_atendente FOREIGN KEY (id_atendente)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_os_tecnico FOREIGN KEY (id_tecnico)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- CORRIGIDO (H3): Substituídas as duas FKs soltas por uma FK Composta. 
    -- Agora o banco proíbe abrir OS com equipamento do cliente 1 para o cliente 2.
    CONSTRAINT fk_os_equipamento_cliente FOREIGN KEY (id_equipamento, id_cliente)
        REFERENCES EQUIPAMENTO (id_equipamento, id_cliente)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_os_data_prevista
        CHECK (data_prevista IS NULL OR data_prevista >= DATE(data_abertura)),
    -- CORRIGIDO (H4): O professor notou que 'Entregue' passava sem diagnóstico.
    CONSTRAINT ck_os_conclusao_exige_diagnostico
        CHECK (status NOT IN ('Concluido', 'Entregue') OR diagnostico_tecnico IS NOT NULL)
) ENGINE=InnoDB;

CREATE INDEX idx_os_atendente   ON ORDEM_SERVICO (id_atendente);
CREATE INDEX idx_os_tecnico     ON ORDEM_SERVICO (id_tecnico);
CREATE INDEX idx_os_equip_cli   ON ORDEM_SERVICO (id_equipamento, id_cliente);
CREATE INDEX idx_os_status      ON ORDEM_SERVICO (status);

DELIMITER $$
CREATE TRIGGER trg_os_rn09_ins
BEFORE INSERT ON ORDEM_SERVICO
FOR EACH ROW
BEGIN
    IF NEW.id_tecnico IS NOT NULL AND
       (SELECT cargo FROM FUNCIONARIO WHERE id_funcionario = NEW.id_tecnico) <> 'Tecnico' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN09: id_tecnico deve referenciar um funcionario com cargo Tecnico.';
    END IF;
    IF (SELECT cargo FROM FUNCIONARIO WHERE id_funcionario = NEW.id_atendente) = 'Tecnico' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN09: id_atendente nao pode ser um funcionario com cargo Tecnico.';
    END IF;
END$$

CREATE TRIGGER trg_os_rn09_upd
BEFORE UPDATE ON ORDEM_SERVICO
FOR EACH ROW
BEGIN
    IF NEW.id_tecnico IS NOT NULL AND
       (SELECT cargo FROM FUNCIONARIO WHERE id_funcionario = NEW.id_tecnico) <> 'Tecnico' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN09: id_tecnico deve referenciar um funcionario com cargo Tecnico.';
    END IF;
    -- CORRIGIDO (H6): Faltava checar o id_atendente no momento do UPDATE
    IF (SELECT cargo FROM FUNCIONARIO WHERE id_funcionario = NEW.id_atendente) = 'Tecnico' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN09: id_atendente nao pode ser um funcionario com cargo Tecnico.';
    END IF;
END$$

-- CORRIGIDO (H7): Faltava a trigger que gera o histórico automaticamente ao mudar status
CREATE TRIGGER trg_os_rn12_historico
AFTER UPDATE ON ORDEM_SERVICO
FOR EACH ROW
BEGIN
    IF NEW.status <> OLD.status THEN
        INSERT INTO HISTORICO_STATUS_OS (id_os, data_hora, status_novo, id_funcionario)
        VALUES (NEW.id_os, CURRENT_TIMESTAMP, NEW.status, COALESCE(NEW.id_tecnico, NEW.id_atendente));
    END IF;
END$$
DELIMITER ;

-- ============================================================
-- 6. Tabela HISTORICO_STATUS_OS (ENTIDADE FRACA) -- Implementa RN12, RN13
-- ============================================================
CREATE TABLE HISTORICO_STATUS_OS (
    -- CORRIGIDO (H8): Adicionado id_historico. PK dupla com DATETIME falha se houver 2 eventos no mesmo segundo.
    id_historico   INT AUTO_INCREMENT,
    id_os          INT NOT NULL,
    data_hora      DATETIME NOT NULL,
    status_novo    ENUM('Aberto','Em Diagnostico','Aguardando Peca',
                         'Em Execucao','Concluido','Entregue','Cancelado') NOT NULL,
    id_funcionario INT NOT NULL,
    CONSTRAINT pk_historico_status_os PRIMARY KEY (id_historico),
    -- CORRIGIDO (H1): Trocado CASCADE por RESTRICT. Assim o SGBD proíbe apagar a OS 
    -- e contorna o problema do MySQL de não disparar trigger em exclusão em cascata.
    CONSTRAINT fk_historico_os FOREIGN KEY (id_os)
        REFERENCES ORDEM_SERVICO (id_os)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_historico_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

DELIMITER $$
CREATE TRIGGER trg_historico_rn13_upd
BEFORE UPDATE ON HISTORICO_STATUS_OS
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN13: registros de HISTORICO_STATUS_OS nao podem ser alterados.';
END$$

CREATE TRIGGER trg_historico_rn13_del
BEFORE DELETE ON HISTORICO_STATUS_OS
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN13: registros de HISTORICO_STATUS_OS nao podem ser excluidos.';
END$$
DELIMITER ;

-- ============================================================
-- 7. Tabela SERVICO_CATALOGO -- Implementa RN14
-- ============================================================
CREATE TABLE SERVICO_CATALOGO (
    id_servico          INT AUTO_INCREMENT,
    nome_servico        VARCHAR(100) NOT NULL,
    preco_base          DECIMAL(10,2) NOT NULL,
    tempo_estimado_min  INT NOT NULL,
    CONSTRAINT pk_servico_catalogo PRIMARY KEY (id_servico),
    CONSTRAINT ck_servico_preco_base CHECK (preco_base > 0),
    CONSTRAINT ck_servico_tempo_estimado CHECK (tempo_estimado_min > 0)
) ENGINE=InnoDB;

-- ============================================================
-- 8. Tabela PECA -- Implementa RN16
-- ============================================================
CREATE TABLE PECA (
    id_peca        INT AUTO_INCREMENT,
    descricao_peca VARCHAR(100) NOT NULL,
    preco_custo    DECIMAL(10,2) NOT NULL,
    preco_venda    DECIMAL(10,2) NOT NULL,
    qtd_estoque    INT NOT NULL DEFAULT 0,
    qtd_minima     INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_peca PRIMARY KEY (id_peca),
    CONSTRAINT ck_peca_precos CHECK (preco_custo >= 0 AND preco_venda >= 0),
    CONSTRAINT ck_peca_qtd_estoque CHECK (qtd_estoque >= 0),
    CONSTRAINT ck_peca_qtd_minima CHECK (qtd_minima >= 0)
) ENGINE=InnoDB;

-- ============================================================
-- 9. Tabela POSSUI_SERVICO (Associativa N:M) -- Implementa RN15
-- ============================================================
CREATE TABLE POSSUI_SERVICO (
    id_servico      INT NOT NULL,
    id_os           INT NOT NULL,
    quantidade      INT NOT NULL DEFAULT 1,
    preco_praticado DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_possui_servico PRIMARY KEY (id_servico, id_os),
    CONSTRAINT fk_possui_servico FOREIGN KEY (id_servico)
        REFERENCES SERVICO_CATALOGO (id_servico)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_possui_os FOREIGN KEY (id_os)
        REFERENCES ORDEM_SERVICO (id_os)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_possui_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_possui_preco CHECK (preco_praticado >= 0)
) ENGINE=InnoDB;

-- ============================================================
-- 10. Tabela UTILIZA_PECA (Associativa N:M) -- Implementa RN17, RN18, RN19
-- ============================================================
CREATE TABLE UTILIZA_PECA (
    id_peca         INT NOT NULL,
    id_os           INT NOT NULL,
    quantidade      INT NOT NULL DEFAULT 1,
    preco_praticado DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_utiliza_peca PRIMARY KEY (id_peca, id_os),
    CONSTRAINT fk_utiliza_peca FOREIGN KEY (id_peca)
        REFERENCES PECA (id_peca)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_utiliza_os FOREIGN KEY (id_os)
        REFERENCES ORDEM_SERVICO (id_os)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_utiliza_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_utiliza_preco CHECK (preco_praticado >= 0)
) ENGINE=InnoDB;

DELIMITER $$
CREATE TRIGGER trg_utiliza_peca_rn18_rn19_ins
BEFORE INSERT ON UTILIZA_PECA
FOR EACH ROW
BEGIN
    DECLARE estoque_atual INT;
    SELECT qtd_estoque INTO estoque_atual FROM PECA WHERE id_peca = NEW.id_peca FOR UPDATE;

    IF estoque_atual < NEW.quantidade THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN18: quantidade solicitada excede o estoque disponivel da peca.';
    END IF;

    UPDATE PECA
       SET qtd_estoque = qtd_estoque - NEW.quantidade
     WHERE id_peca = NEW.id_peca;
END$$

-- CORRIGIDO (H2): Faltava trigger para devolver a peça ao estoque se for deletada da OS
CREATE TRIGGER trg_utiliza_peca_rn19_del
AFTER DELETE ON UTILIZA_PECA
FOR EACH ROW
BEGIN
    UPDATE PECA
       SET qtd_estoque = qtd_estoque + OLD.quantidade
     WHERE id_peca = OLD.id_peca;
END$$
DELIMITER ;

-- ============================================================
-- VIEW de apoio a RN20 (valor total da OS - atributo derivado por consulta)
-- ============================================================
CREATE OR REPLACE VIEW vw_os_valor_total AS
SELECT
    os.id_os,
    COALESCE(serv.total_servicos, 0) + COALESCE(pec.total_pecas, 0) AS valor_total
FROM ORDEM_SERVICO os
LEFT JOIN (
    SELECT id_os, SUM(quantidade * preco_praticado) AS total_servicos
    FROM POSSUI_SERVICO GROUP BY id_os
) serv ON serv.id_os = os.id_os
LEFT JOIN (
    SELECT id_os, SUM(quantidade * preco_praticado) AS total_pecas
    FROM UTILIZA_PECA GROUP BY id_os
) pec ON pec.id_os = os.id_os;