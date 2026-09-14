-- ============================================================
-- ARTEFATO A4: SCRIPT DDL (DEFINIÇÃO DE DADOS - SGATM)
-- ============================================================

CREATE DATABASE IF NOT EXISTS sgatm_db
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE sgatm_db;

SET NAMES 'utf8mb4';

-- 1. Tabela PESSOA (Tabela Base)
CREATE TABLE PESSOA (
    id_pessoa INT AUTO_INCREMENT PRIMARY KEY,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefone VARCHAR(20)
);

-- 2. Tabela CLIENTE
CREATE TABLE CLIENTE (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    data_cadastro DATE NOT NULL,
    id_pessoa INT NOT NULL,
    CONSTRAINT fk_cliente_pessoa FOREIGN KEY (id_pessoa) REFERENCES PESSOA(id_pessoa)
);

-- 3. Tabela FUNCIONARIO
CREATE TABLE FUNCIONARIO (
    id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
    cargo VARCHAR(50) NOT NULL,
    data_admissao DATE NOT NULL,
    salario_base DECIMAL(10,2) NOT NULL,
    id_pessoa INT NOT NULL,
    id_gerente INT,
    CONSTRAINT fk_funcionario_pessoa FOREIGN KEY (id_pessoa) REFERENCES PESSOA(id_pessoa),
    CONSTRAINT fk_funcionario_gerente FOREIGN KEY (id_gerente) REFERENCES FUNCIONARIO(id_funcionario)
);

-- 4. Tabela EQUIPAMENTO
CREATE TABLE EQUIPAMENTO (
    id_equipamento INT AUTO_INCREMENT PRIMARY KEY,
    tipo_aparelho VARCHAR(50) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    numero_serie VARCHAR(50) NOT NULL UNIQUE,
    id_cliente INT NOT NULL,
    CONSTRAINT fk_equipamento_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente)
);

-- 5. Tabela ORDEM_SERVICO
CREATE TABLE ORDEM_SERVICO (
    id_os INT AUTO_INCREMENT PRIMARY KEY,
    data_abertura DATETIME NOT NULL,
    data_prevista DATE,
    defeito_relatado VARCHAR(500) NOT NULL,
    diagnostico_tecnico VARCHAR(500),
    status VARCHAR(30) NOT NULL DEFAULT 'Aberto',
    id_atendente INT NOT NULL,
    id_tecnico INT,
    id_cliente INT NOT NULL,
    id_equipamento INT NOT NULL,
    CONSTRAINT fk_os_atendente FOREIGN KEY (id_atendente) REFERENCES FUNCIONARIO(id_funcionario),
    CONSTRAINT fk_os_tecnico FOREIGN KEY (id_tecnico) REFERENCES FUNCIONARIO(id_funcionario),
    CONSTRAINT fk_os_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente),
    CONSTRAINT fk_os_equipamento FOREIGN KEY (id_equipamento) REFERENCES EQUIPAMENTO(id_equipamento)
);

-- 6. Tabela HISTORICO_STATUS_OS
CREATE TABLE HISTORICO_STATUS_OS (
    id_historico INT AUTO_INCREMENT PRIMARY KEY,
    data_hora DATETIME NOT NULL,
    status_novo VARCHAR(30) NOT NULL,
    id_os INT NOT NULL,
    CONSTRAINT fk_historico_os FOREIGN KEY (id_os) REFERENCES ORDEM_SERVICO(id_os)
);

-- 7. Tabela SERVICO_CATALOGO
CREATE TABLE SERVICO_CATALOGO (
    id_servico INT AUTO_INCREMENT PRIMARY KEY,
    nome_servico VARCHAR(100) NOT NULL,
    preco_base DECIMAL(10,2) NOT NULL,
    tempo_estimado_min INT NOT NULL
);

-- 8. Tabela POSSUI_SERVICO (Associativa N:M)
CREATE TABLE POSSUI_SERVICO (
    id_servico INT NOT NULL,
    id_os INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    preco_praticado DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_servico, id_os),
    CONSTRAINT fk_possui_servico FOREIGN KEY (id_servico) REFERENCES SERVICO_CATALOGO(id_servico),
    CONSTRAINT fk_possui_os FOREIGN KEY (id_os) REFERENCES ORDEM_SERVICO(id_os)
);

-- 9. Tabela PECA
CREATE TABLE PECA (
    id_peca INT AUTO_INCREMENT PRIMARY KEY,
    descricao_peca VARCHAR(100) NOT NULL,
    preco_custo DECIMAL(10,2) NOT NULL,
    preco_venda DECIMAL(10,2) NOT NULL,
    qtd_estoque INT NOT NULL DEFAULT 0,
    qtd_minima INT NOT NULL DEFAULT 0
);

-- 10. Tabela UTILIZA_PECA (Associativa N:M)
CREATE TABLE UTILIZA_PECA (
    id_peca INT NOT NULL,
    id_os INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    preco_praticado DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_peca, id_os),
    CONSTRAINT fk_utiliza_peca FOREIGN KEY (id_peca) REFERENCES PECA(id_peca),
    CONSTRAINT fk_utiliza_os FOREIGN KEY (id_os) REFERENCES ORDEM_SERVICO(id_os)
);