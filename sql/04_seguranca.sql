-- ============================================================
-- ARTEFATO B5: SEGURANÇA E CONTROLE DE ACESSO (SGATM)
-- Sistema de Gestão de Assistência Técnica e Manutenção
-- SGBD: MySQL 8.0
-- Responsável: Lorena Dalmagro
--
-- Ordem de execução: 01_ddl.sql -> 02_carga.sql -> 04_seguranca.sql
-- Executar como root (ou usuário com CREATE USER, CREATE ROLE e GRANT OPTION).
--
-- Conteúdo:
--   1. Armazenamento seguro de senhas (hash + sal)
--   2. Visões restritivas (colunas que cada perfil pode ver)
--   3. Perfis (roles) com GRANT aplicando o menor privilégio
--   4. Usuários reais do banco, ligados aos perfis
--   5. Exemplos de REVOKE
--   6. Roteiro de testes (comentado, para rodar na demonstração)
-- ============================================================

USE sgatm_db;

-- ============================================================
-- 1. SENHAS DOS USUÁRIOS DA APLICAÇÃO (HASH + SAL)
-- ------------------------------------------------------------
-- Nunca guardamos a senha em texto claro. Para cada usuário:
--   * sal  = 16 bytes aleatórios (RANDOM_BYTES), em hexadecimal.
--            Duas pessoas com a mesma senha ficam com hashes diferentes,
--            o que inutiliza tabelas pré-calculadas (rainbow tables).
--   * hash = SHA-256 de (sal + senha), repetido 5.000 vezes.
--            A repetição (key stretching) deixa cada tentativa de
--            adivinhação mais lenta, dificultando ataque de força bruta.
-- Observação: em produção o ideal é gerar o hash na aplicação com
-- bcrypt ou Argon2, algoritmos feitos para senha. Aqui o cálculo fica
-- no banco para que o mecanismo seja visível e testável em SQL.
-- ============================================================

-- Permite rodar o script de novo sem erro.
DROP PROCEDURE IF EXISTS sp_autenticar;
DROP PROCEDURE IF EXISTS sp_criar_usuario;
DROP FUNCTION  IF EXISTS fn_hash_senha;
DROP TABLE     IF EXISTS USUARIO_SISTEMA;

CREATE TABLE USUARIO_SISTEMA (
    id_usuario       INT AUTO_INCREMENT,
    id_funcionario   INT          NOT NULL,
    login            VARCHAR(50)  NOT NULL,
    senha_hash       CHAR(64)     NOT NULL,   -- SHA-256 em hexadecimal
    salt             CHAR(32)     NOT NULL,   -- 16 bytes em hexadecimal
    tentativas_falhas TINYINT     NOT NULL DEFAULT 0,
    bloqueado        BOOLEAN      NOT NULL DEFAULT FALSE,
    data_criacao     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_usuario_sistema PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuario_login UNIQUE (login),
    CONSTRAINT uq_usuario_funcionario UNIQUE (id_funcionario),
    CONSTRAINT fk_usuario_funcionario FOREIGN KEY (id_funcionario)
        REFERENCES FUNCIONARIO (id_funcionario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_usuario_tentativas CHECK (tentativas_falhas >= 0)
) ENGINE=InnoDB;

DELIMITER $$

-- Calcula o hash com sal e 5.000 iterações de SHA-256.
CREATE FUNCTION fn_hash_senha(p_senha VARCHAR(255), p_salt CHAR(32))
RETURNS CHAR(64)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_hash CHAR(64);
    DECLARE i INT DEFAULT 1;
    SET v_hash = SHA2(CONCAT(p_salt, p_senha), 256);
    WHILE i < 5000 DO
        SET v_hash = SHA2(CONCAT(p_salt, v_hash), 256);
        SET i = i + 1;
    END WHILE;
    RETURN v_hash;
END$$

-- Cadastra um usuário da aplicação: gera o sal e grava só o hash.
CREATE PROCEDURE sp_criar_usuario(
    IN p_id_funcionario INT,
    IN p_login          VARCHAR(50),
    IN p_senha          VARCHAR(255)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_salt CHAR(32);
    IF CHAR_LENGTH(p_senha) < 8 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A senha deve ter pelo menos 8 caracteres.';
    END IF;
    SET v_salt = HEX(RANDOM_BYTES(16));
    INSERT INTO USUARIO_SISTEMA (id_funcionario, login, senha_hash, salt)
    VALUES (p_id_funcionario, p_login, fn_hash_senha(p_senha, v_salt), v_salt);
END$$

-- Autentica um login. Devolve o funcionário e o cargo se a senha conferir;
-- senão devolve NULL. Após 5 erros seguidos, o usuário é bloqueado.
-- A aplicação usa o cargo devolvido para escolher com qual conta do banco
-- (perfil) vai se conectar a partir daí.
CREATE PROCEDURE sp_autenticar(
    IN  p_login          VARCHAR(50),
    IN  p_senha          VARCHAR(255),
    OUT p_id_funcionario INT,
    OUT p_cargo          VARCHAR(20)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_id_usuario INT;
    DECLARE v_hash CHAR(64);
    DECLARE v_salt CHAR(32);
    DECLARE v_bloqueado BOOLEAN;

    SET p_id_funcionario = NULL;
    SET p_cargo = NULL;

    SELECT id_usuario, senha_hash, salt, bloqueado
      INTO v_id_usuario, v_hash, v_salt, v_bloqueado
      FROM USUARIO_SISTEMA
     WHERE login = p_login;

    IF v_id_usuario IS NOT NULL AND v_bloqueado = FALSE THEN
        IF fn_hash_senha(p_senha, v_salt) = v_hash THEN
            UPDATE USUARIO_SISTEMA SET tentativas_falhas = 0
             WHERE id_usuario = v_id_usuario;
            SELECT u.id_funcionario, f.cargo
              INTO p_id_funcionario, p_cargo
              FROM USUARIO_SISTEMA u
              JOIN FUNCIONARIO f ON f.id_funcionario = u.id_funcionario
             WHERE u.id_usuario = v_id_usuario;
        ELSE
            UPDATE USUARIO_SISTEMA
               SET tentativas_falhas = tentativas_falhas + 1,
                   bloqueado = (tentativas_falhas + 1 >= 5)
             WHERE id_usuario = v_id_usuario;
        END IF;
    END IF;
END$$

DELIMITER ;

-- Usuários de demonstração (senhas fictícias, só para teste/apresentação).
CALL sp_criar_usuario(1, 'carlos.gerente', 'Gerente@2026');
CALL sp_criar_usuario(3, 'marcos.atend',   'Atende@2026');
CALL sp_criar_usuario(6, 'fernando.tec',   'Tecnico@2026');


-- ============================================================
-- 2. VISÕES RESTRITIVAS
-- ------------------------------------------------------------
-- Em vez de liberar a tabela inteira, cada perfil recebe GRANT só
-- na visão, que expõe apenas as colunas necessárias ao seu trabalho.
-- ============================================================

-- Técnico precisa saber de quem é o aparelho, mas não precisa do
-- contato nem do CPF completo do cliente (LGPD: minimização).
CREATE OR REPLACE VIEW vw_cliente_tecnico AS
SELECT
    c.id_cliente,
    p.nome,
    CONCAT('***.', SUBSTRING(p.cpf, 4, 3), '.', SUBSTRING(p.cpf, 7, 3), '-**') AS cpf_mascarado
FROM CLIENTE c
JOIN PESSOA p ON p.id_pessoa = c.id_pessoa;

-- Lista de funcionários sem salário e sem CPF. Usada por atendentes
-- (para escolher o técnico da OS) e por técnicos.
CREATE OR REPLACE VIEW vw_funcionario_publico AS
SELECT
    f.id_funcionario,
    p.nome,
    f.cargo,
    f.id_gerente
FROM FUNCIONARIO f
JOIN PESSOA p ON p.id_pessoa = f.id_pessoa;

-- Estoque de peças sem o preço de custo (informação comercial do gerente).
CREATE OR REPLACE VIEW vw_peca_estoque AS
SELECT
    id_peca,
    descricao_peca,
    preco_venda,
    qtd_estoque,
    qtd_minima
FROM PECA;


-- ============================================================
-- 3. PERFIS (ROLES) COM MENOR PRIVILÉGIO
-- ------------------------------------------------------------
-- Regra geral: ninguém recebe privilégio no banco inteiro (sgatm_db.*),
-- ninguém recebe DROP/ALTER, e nenhum perfil acessa USUARIO_SISTEMA.
-- O histórico de status (RN13) é só leitura para todos; as gravações
-- nele são feitas pela trigger trg_os_rn12_historico, que executa com
-- os privilégios de quem a criou, não do usuário que fez o UPDATE.
-- O mesmo vale para as triggers de estoque (RN18/RN19).
-- ============================================================

DROP ROLE IF EXISTS 'r_atendente', 'r_tecnico', 'r_gerente', 'r_autenticacao';
CREATE ROLE 'r_atendente', 'r_tecnico', 'r_gerente', 'r_autenticacao';

-- ---------- ATENDENTE: recebe o cliente e abre a OS ----------
GRANT SELECT, INSERT, UPDATE ON sgatm_db.PESSOA      TO 'r_atendente';
GRANT SELECT, INSERT, UPDATE ON sgatm_db.CLIENTE     TO 'r_atendente';
GRANT SELECT, INSERT, UPDATE ON sgatm_db.EQUIPAMENTO TO 'r_atendente';
GRANT SELECT, INSERT         ON sgatm_db.ORDEM_SERVICO TO 'r_atendente';
-- Na OS já aberta, o atendente só altera técnico, previsão e status
-- (ex.: marcar 'Entregue' quando o cliente busca o aparelho).
GRANT UPDATE (id_tecnico, data_prevista, status) ON sgatm_db.ORDEM_SERVICO TO 'r_atendente';
GRANT SELECT ON sgatm_db.SERVICO_CATALOGO       TO 'r_atendente';
GRANT SELECT ON sgatm_db.HISTORICO_STATUS_OS    TO 'r_atendente';
GRANT SELECT ON sgatm_db.vw_os_valor_total      TO 'r_atendente';
GRANT SELECT ON sgatm_db.vw_funcionario_publico TO 'r_atendente';
-- Sem acesso a: FUNCIONARIO (salário), PECA (custo), lançamento de peças/serviços.

-- ---------- TÉCNICO: diagnostica e executa o reparo ----------
GRANT SELECT ON sgatm_db.ORDEM_SERVICO TO 'r_tecnico';
-- Na OS, o técnico só mexe no diagnóstico e no status.
GRANT UPDATE (diagnostico_tecnico, status) ON sgatm_db.ORDEM_SERVICO TO 'r_tecnico';
GRANT SELECT ON sgatm_db.EQUIPAMENTO         TO 'r_tecnico';
GRANT SELECT ON sgatm_db.SERVICO_CATALOGO    TO 'r_tecnico';
GRANT SELECT ON sgatm_db.HISTORICO_STATUS_OS TO 'r_tecnico';
GRANT SELECT, INSERT, DELETE ON sgatm_db.POSSUI_SERVICO TO 'r_tecnico';
GRANT SELECT, INSERT, DELETE ON sgatm_db.UTILIZA_PECA   TO 'r_tecnico';
GRANT SELECT ON sgatm_db.vw_cliente_tecnico     TO 'r_tecnico';
GRANT SELECT ON sgatm_db.vw_funcionario_publico TO 'r_tecnico';
GRANT SELECT ON sgatm_db.vw_peca_estoque        TO 'r_tecnico';
-- Sem acesso a: PESSOA (dados pessoais completos), FUNCIONARIO, PECA (custo).

-- ---------- GERENTE: supervisiona, cuida de equipe, preços e estoque ----------
GRANT SELECT ON sgatm_db.PESSOA              TO 'r_gerente';
GRANT SELECT ON sgatm_db.CLIENTE             TO 'r_gerente';
GRANT SELECT ON sgatm_db.EQUIPAMENTO         TO 'r_gerente';
GRANT SELECT ON sgatm_db.ORDEM_SERVICO       TO 'r_gerente';
GRANT SELECT ON sgatm_db.HISTORICO_STATUS_OS TO 'r_gerente';
GRANT SELECT ON sgatm_db.POSSUI_SERVICO      TO 'r_gerente';
GRANT SELECT ON sgatm_db.UTILIZA_PECA        TO 'r_gerente';
GRANT SELECT ON sgatm_db.vw_os_valor_total   TO 'r_gerente';
GRANT SELECT, INSERT, UPDATE ON sgatm_db.FUNCIONARIO      TO 'r_gerente';
GRANT INSERT, UPDATE         ON sgatm_db.PESSOA           TO 'r_gerente';
GRANT SELECT, INSERT, UPDATE ON sgatm_db.SERVICO_CATALOGO TO 'r_gerente';
GRANT SELECT, INSERT, UPDATE ON sgatm_db.PECA             TO 'r_gerente';
-- Nem o gerente apaga OS, histórico ou dados pessoais: exclusões ficam
-- com o administrador do banco, por rastreabilidade.

-- ---------- AUTENTICAÇÃO: conta usada pela aplicação só para o login ----------
-- Não lê nenhuma tabela: só pode chamar a procedure que confere a senha.
GRANT EXECUTE ON PROCEDURE sgatm_db.sp_autenticar TO 'r_autenticacao';

-- Quando a tabela de auditoria da B6 existir, liberar leitura ao gerente:
-- GRANT SELECT ON sgatm_db.<TABELA_AUDITORIA> TO 'r_gerente';


-- ============================================================
-- 4. USUÁRIOS DO BANCO (CONTAS REAIS) LIGADOS AOS PERFIS
-- ------------------------------------------------------------
-- IDENTIFIED BY RANDOM PASSWORD faz o MySQL gerar a senha e mostrá-la
-- uma única vez no resultado deste comando. Assim nenhuma senha de
-- banco fica escrita neste script versionado (exigência da B2).
-- Copie as senhas geradas para o arquivo .env da aplicação, que fica
-- fora do Git (.gitignore).
-- ============================================================

-- Senhas geradas com 12 caracteres (o padrão do MySQL é 20).
-- Continuam aleatórias, mas ficam mais fáceis de copiar.
SET SESSION generated_random_password_length = 12;

DROP USER IF EXISTS 'sgatm_atendente'@'localhost', 'sgatm_tecnico'@'localhost',
                    'sgatm_gerente'@'localhost',   'sgatm_auth'@'localhost';

CREATE USER 'sgatm_atendente'@'localhost' IDENTIFIED BY RANDOM PASSWORD;
CREATE USER 'sgatm_tecnico'@'localhost'   IDENTIFIED BY RANDOM PASSWORD;
CREATE USER 'sgatm_gerente'@'localhost'   IDENTIFIED BY RANDOM PASSWORD;
CREATE USER 'sgatm_auth'@'localhost'      IDENTIFIED BY RANDOM PASSWORD;

GRANT 'r_atendente'    TO 'sgatm_atendente'@'localhost';
GRANT 'r_tecnico'      TO 'sgatm_tecnico'@'localhost';
GRANT 'r_gerente'      TO 'sgatm_gerente'@'localhost';
GRANT 'r_autenticacao' TO 'sgatm_auth'@'localhost';

-- Sem isso o perfil existe, mas não fica ativo ao fazer login.
SET DEFAULT ROLE ALL TO
    'sgatm_atendente'@'localhost', 'sgatm_tecnico'@'localhost',
    'sgatm_gerente'@'localhost',   'sgatm_auth'@'localhost';


-- ============================================================
-- 5. REVOKE
-- ------------------------------------------------------------
-- 5.1 Ajuste de privilégio. Numa primeira versão, o atendente recebia
-- UPDATE na tabela ORDEM_SERVICO inteira. Isso deixaria ele alterar o
-- defeito relatado e o diagnóstico técnico, que não são tarefa dele.
-- O UPDATE geral é revogado; ficam só as colunas liberadas na seção 3.
-- ============================================================
GRANT  UPDATE ON sgatm_db.ORDEM_SERVICO TO   'r_atendente';   -- versão antiga
REVOKE UPDATE ON sgatm_db.ORDEM_SERVICO FROM 'r_atendente';   -- correção
-- Atenção: no MySQL, o REVOKE na tabela também apaga os privilégios de
-- coluna. Por isso as colunas permitidas são concedidas de novo:
GRANT UPDATE (id_tecnico, data_prevista, status) ON sgatm_db.ORDEM_SERVICO TO 'r_atendente';

-- ------------------------------------------------------------
-- 5.2 Desligamento de funcionário. Quando alguém sai da empresa,
-- o perfil é retirado e a conta é travada (os registros antigos dele,
-- como histórico de OS, continuam, porque não se apaga auditoria).
-- Exemplo com uma conta temporária criada só para mostrar o fluxo:
-- ------------------------------------------------------------
DROP USER IF EXISTS 'sgatm_tecnico_temp'@'localhost';
CREATE USER 'sgatm_tecnico_temp'@'localhost' IDENTIFIED BY RANDOM PASSWORD;
GRANT  'r_tecnico' TO   'sgatm_tecnico_temp'@'localhost';
REVOKE 'r_tecnico' FROM 'sgatm_tecnico_temp'@'localhost';
ALTER USER 'sgatm_tecnico_temp'@'localhost' ACCOUNT LOCK;

-- Conferência dos privilégios finais de cada perfil:
SHOW GRANTS FOR 'r_atendente';
SHOW GRANTS FOR 'r_tecnico';
SHOW GRANTS FOR 'r_gerente';
SHOW GRANTS FOR 'r_autenticacao';


-- ============================================================
-- 6. ROTEIRO DE TESTES (rodar na demonstração, "mesmo login sob
--    dois perfis"). Em cada terminal:
--      mysql -u sgatm_atendente -p sgatm_db
--      mysql -u sgatm_gerente   -p sgatm_db
-- ============================================================
-- Como ATENDENTE:
--   SELECT * FROM FUNCIONARIO;                       -- NEGADO (salário)
--   SELECT * FROM vw_funcionario_publico;            -- OK, sem salário
--   UPDATE ORDEM_SERVICO SET diagnostico_tecnico = 'x' WHERE id_os = 1;  -- NEGADO
--   UPDATE ORDEM_SERVICO SET data_prevista = '2027-01-10' WHERE id_os = 1; -- OK
--
-- Como TÉCNICO:
--   SELECT * FROM PESSOA;                            -- NEGADO
--   SELECT * FROM vw_cliente_tecnico;                -- OK, CPF mascarado
--   SELECT preco_custo FROM PECA;                    -- NEGADO
--   DELETE FROM HISTORICO_STATUS_OS;                 -- NEGADO (RN13)
--
-- Como GERENTE:
--   SELECT * FROM FUNCIONARIO;                       -- OK
--   SELECT * FROM USUARIO_SISTEMA;                   -- NEGADO (ninguém lê hashes)
--   DELETE FROM ORDEM_SERVICO WHERE id_os = 1;       -- NEGADO
--
-- Como AUTENTICAÇÃO (sgatm_auth), testando a senha:
--   CALL sp_autenticar('fernando.tec', 'Tecnico@2026', @id, @cargo);
--   SELECT @id, @cargo;                              -- 6, Tecnico
--   CALL sp_autenticar('fernando.tec', 'senhaerrada', @id, @cargo);
--   SELECT @id, @cargo;                              -- NULL, NULL
--   SELECT * FROM USUARIO_SISTEMA;                   -- NEGADO
--
-- Prova de que a senha não está em texto claro (como root):
--   SELECT login, salt, senha_hash FROM USUARIO_SISTEMA;
-- ============================================================
