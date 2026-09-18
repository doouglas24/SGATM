-- ============================================================
-- ARTEFATO A6: SCRIPT DDL (DEFINIÇÃO DE DADOS - SGATM)
-- Sistema de Gestão de Assistência Técnica e Manutenção
-- SGBD: MySQL 8.0
--
-- Revisão: mantido o design original da equipe (PESSOA/CLIENTE/
-- FUNCIONARIO/EQUIPAMENTO/ORDEM_SERVICO/HISTORICO_STATUS_OS/
-- SERVICO_CATALOGO/PECA/POSSUI_SERVICO/UTILIZA_PECA). Foram feitos
-- apenas os ajustes exigidos pelo enunciado e pelas RNs do próprio
-- documento de escopo (ver comentários "-- CORRIGIDO:" ao longo do
-- arquivo para localizar cada mudança em relação à versão anterior).
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
    cpf       VARCHAR(14)  NOT NULL,
    nome      VARCHAR(100) NOT NULL,
    email     VARCHAR(100) NOT NULL,
    telefone  VARCHAR(20)  NULL,
    CONSTRAINT pk_pessoa PRIMARY KEY (id_pessoa),
    -- CORRIGIDO: UNIQUE nomeados (RN01: CPF e e-mail únicos)
    CONSTRAINT uq_pessoa_cpf   UNIQUE (cpf),
    CONSTRAINT uq_pessoa_email UNIQUE (email)
) ENGINE=InnoDB;

-- ============================================================
-- 2. Tabela CLIENTE -- Implementa RN02
-- ============================================================
CREATE TABLE CLIENTE (
    id_cliente    INT AUTO_INCREMENT,
    data_cadastro DATE NOT NULL,
    id_pessoa     INT  NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    -- CORRIGIDO: UNIQUE nomeado — um registro de PESSOA só vira UM cliente (RN02)
    CONSTRAINT uq_cliente_pessoa UNIQUE (id_pessoa),
    -- CORRIGIDO: ON DELETE/ON UPDATE explícitos
    CONSTRAINT fk_cliente_pessoa FOREIGN KEY (id_pessoa)
        REFERENCES PESSOA (id_pessoa)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 3. Tabela FUNCIONARIO -- Implementa RN03, RN04
-- ============================================================
CREATE TABLE FUNCIONARIO (
    id_funcionario  INT AUTO_INCREMENT,
    -- CORRIGIDO: cargo virou ENUM para casar com as comparações usadas
    -- nas RN04/RN09/etc. (evita "Tecnico" vs "tecnico" vs "Técnico")
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
    -- CORRIGIDO: autorrelacionamento com ON DELETE/ON UPDATE explícitos
    CONSTRAINT fk_funcionario_gerente FOREIGN KEY (id_gerente)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- CORRIGIDO: preço/salário não pode ser negativo
    CONSTRAINT ck_funcionario_salario CHECK (salario_base >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_funcionario_gerente ON FUNCIONARIO (id_gerente);

-- CORRIGIDO: trigger para RN04 — Técnico deve obrigatoriamente ter um
-- Gerente associado como supervisor. Não é feito via CHECK porque o
-- MySQL não permite CHECK sobre coluna que participa de ação
-- referencial de FK (id_gerente tem ON DELETE/ON UPDATE definidos).
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
    -- CORRIGIDO: RN06 diz "quando informado" -> não pode ser NOT NULL
    numero_serie   VARCHAR(50) NULL,
    id_cliente     INT NOT NULL,
    CONSTRAINT pk_equipamento PRIMARY KEY (id_equipamento),
    -- CORRIGIDO: UNIQUE nomeado. Em NULL o MySQL permite múltiplos NULLs,
    -- então a unicidade só passa a valer quando o numero_serie é informado.
    CONSTRAINT uq_equipamento_numero_serie UNIQUE (numero_serie),
    CONSTRAINT fk_equipamento_cliente FOREIGN KEY (id_cliente)
        REFERENCES CLIENTE (id_cliente)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_equipamento_cliente ON EQUIPAMENTO (id_cliente);

-- ============================================================
-- 5. Tabela ORDEM_SERVICO -- Implementa RN07, RN08, RN09, RN11
-- ============================================================
-- NOTA DE MODELAGEM (não é bug de sintaxe, e sim ponto para o A4/A5):
-- id_cliente aqui é redundante com id_equipamento -> EQUIPAMENTO.id_cliente
-- (dependência transitiva id_os -> id_equipamento -> id_cliente). Mantido
-- porque a RN07 pede explicitamente os dois vínculos; documentem essa
-- decisão como desnormalização proposital no A4/A5 (ou removam a coluna
-- e obtenham o cliente via JOIN, se preferirem 3FN estrita).
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
    -- CORRIGIDO: status virou ENUM pelo mesmo motivo do cargo
    status              ENUM('Aberto','Em Diagnostico','Aguardando Peca',
                              'Em Execucao','Concluido','Entregue','Cancelado')
                        NOT NULL DEFAULT 'Aberto',
    CONSTRAINT pk_ordem_servico PRIMARY KEY (id_os),
    CONSTRAINT fk_os_atendente FOREIGN KEY (id_atendente)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- CORRIGIDO: RN09 — só Técnico pode ser responsável. Aqui a FK aponta
    -- para FUNCIONARIO (não existe tabela TECNICO própria no design de
    -- vocês), então a exclusividade de cargo é garantida por trigger abaixo.
    CONSTRAINT fk_os_tecnico FOREIGN KEY (id_tecnico)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_os_cliente FOREIGN KEY (id_cliente)
        REFERENCES CLIENTE (id_cliente)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_os_equipamento FOREIGN KEY (id_equipamento)
        REFERENCES EQUIPAMENTO (id_equipamento)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- CORRIGIDO: RN11 — data prevista não pode ser anterior à abertura
    CONSTRAINT ck_os_data_prevista
        CHECK (data_prevista IS NULL OR data_prevista >= DATE(data_abertura)),
    -- CORRIGIDO: RN10 (parte verificável no banco) — só pode estar
    -- Concluido se já existir diagnóstico técnico registrado
    CONSTRAINT ck_os_conclusao_exige_diagnostico
        CHECK (status <> 'Concluido' OR diagnostico_tecnico IS NOT NULL)
) ENGINE=InnoDB;

CREATE INDEX idx_os_atendente   ON ORDEM_SERVICO (id_atendente);
CREATE INDEX idx_os_tecnico     ON ORDEM_SERVICO (id_tecnico);
CREATE INDEX idx_os_cliente     ON ORDEM_SERVICO (id_cliente);
CREATE INDEX idx_os_equipamento ON ORDEM_SERVICO (id_equipamento);
CREATE INDEX idx_os_status      ON ORDEM_SERVICO (status);

-- CORRIGIDO: trigger para RN09 — id_tecnico só pode referenciar um
-- FUNCIONARIO com cargo = 'Tecnico' (o banco não modela isso via FK
-- porque não existe tabela TECNICO separada no design da equipe).
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
END$$
DELIMITER ;

-- ============================================================
-- 6. Tabela HISTORICO_STATUS_OS (ENTIDADE FRACA) -- Implementa RN12, RN13
-- ============================================================
-- CORRIGIDO: a RN12 descreve isto como "entidade fraca + atributo
-- temporal", mas a versão anterior usava id_historico AUTO_INCREMENT
-- como PK própria (entidade forte). A PK agora é composta por
-- (id_os, data_hora) — a existência do histórico depende da OS.
-- Também foi adicionada a coluna id_funcionario, que a própria RN12
-- exige ("o funcionário que realizou a alteração") e que faltava.
CREATE TABLE HISTORICO_STATUS_OS (
    id_os          INT NOT NULL,
    data_hora      DATETIME NOT NULL,
    status_novo    ENUM('Aberto','Em Diagnostico','Aguardando Peca',
                         'Em Execucao','Concluido','Entregue','Cancelado') NOT NULL,
    id_funcionario INT NOT NULL,
    CONSTRAINT pk_historico_status_os PRIMARY KEY (id_os, data_hora),
    CONSTRAINT fk_historico_os FOREIGN KEY (id_os)
        REFERENCES ORDEM_SERVICO (id_os)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_historico_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- CORRIGIDO: trigger para RN13 — proibe UPDATE e DELETE no histórico
-- (auditoria append-only). O MySQL não tem essa trava nativa.
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
    -- CORRIGIDO: RN14 — preço base > 0 e tempo estimado > 0
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
    -- CORRIGIDO: RN16 — preços e quantidades não podem ser negativos
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
    -- CORRIGIDO: RN15 — quantidade e preço praticado válidos
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
    -- CORRIGIDO: RN17 — quantidade e preço praticado válidos
    CONSTRAINT ck_utiliza_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_utiliza_preco CHECK (preco_praticado >= 0)
) ENGINE=InnoDB;

-- CORRIGIDO: trigger para RN18 (não deixa usar mais peça do que há em
-- estoque) e RN19 (decrementa o estoque automaticamente ao lançar a
-- peça na OS). As duas regras foram reclassificadas de [Aplicação]
-- para [Restrição de Banco], porque "automaticamente" e "não deve
-- permitir" são garantias mais fortes quando ficam no SGBD.
DELIMITER $$
CREATE TRIGGER trg_utiliza_peca_rn18_rn19
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
