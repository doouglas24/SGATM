-- ============================================================
-- ARTEFATO A7: SCRIPT DE CARGA DE DADOS (DML - SGATM)
-- Sistema de Gestão de Assistência Técnica e Manutenção
-- SGBD: MySQL 8.0
--
-- Descrição: Povoamento inicial com dados realistas, casos de
-- contorno propositais (campos NULL opcionais, OSs em aberto,
-- históricos múltiplos por OS) e estrita observância das regras
-- de negócio e triggers implementadas no script DDL.
-- ============================================================

USE sgatm_db;

-- Desabilita temporariamente verificações de FK durante a carga limpa se necessário
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE UTILIZA_PECA;
TRUNCATE TABLE POSSUI_SERVICO;
TRUNCATE TABLE HISTORICO_STATUS_OS;
TRUNCATE TABLE ORDEM_SERVICO;
TRUNCATE TABLE PECA;
TRUNCATE TABLE SERVICO_CATALOGO;
TRUNCATE TABLE EQUIPAMENTO;
TRUNCATE TABLE FUNCIONARIO;
TRUNCATE TABLE CLIENTE;
TRUNCATE TABLE PESSOA;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 1. POVOAMENTO DA TABELA PESSOA (50 registros)
-- ============================================================
INSERT INTO PESSOA (id_pessoa, cpf, nome, email, telefone) VALUES
-- Funcionários (1-10)
(1, '111.222.333-01', 'Carlos Eduardo Lima', 'carlos.lima@sgatm.com.br', '(61) 98111-0001'),
(2, '111.222.333-02', 'Ana Paula Ribeiro', 'ana.ribeiro@sgatm.com.br', '(61) 98111-0002'),
(3, '111.222.333-03', 'Marcos Vinicius Souza', 'marcos.souza@sgatm.com.br', '(61) 98111-0003'),
(4, '111.222.333-04', 'Juliana Mendes Rocha', 'juliana.rocha@sgatm.com.br', '(61) 98111-0004'),
(5, '111.222.333-05', 'Roberto Fonseca Barbosa', 'roberto.barbosa@sgatm.com.br', NULL),
(6, '111.222.333-06', 'Fernando Castro Alves', 'fernando.alves@sgatm.com.br', '(61) 98111-0006'),
(7, '111.222.333-07', 'Lucas Prado Martins', 'lucas.martins@sgatm.com.br', '(61) 98111-0007'),
(8, '111.222.333-08', 'Beatriz Oliveira Santos', 'beatriz.santos@sgatm.com.br', '(61) 98111-0008'),
(9, '111.222.333-09', 'Diego Ferreira Ramos', 'diego.ramos@sgatm.com.br', '(61) 98111-0009'),
(10, '111.222.333-10', 'Patricia Gomez Silva', 'patricia.silva@sgatm.com.br', NULL),
-- Clientes (11-50)
(11, '222.333.444-11', 'Adriana Maria Guimaraes', 'adriana.guimaraes@gmail.com', '(61) 99222-0011'),
(12, '222.333.444-12', 'Bruno Henrique Costa', 'bruno.costa@hotmail.com', '(61) 99222-0012'),
(13, '222.333.444-13', 'Camila Xavier Pires', 'camila.pires@yahoo.com.br', '(61) 99222-0013'),
(14, '222.333.444-14', 'Daniel Nogueira Faria', 'daniel.faria@outlook.com', NULL),
(15, '222.333.444-15', 'Eduardo Augusto Monteiro', 'eduardo.monteiro@gmail.com', '(61) 99222-0015'),
(16, '222.333.444-16', 'Fernanda Lopes Viana', 'fernanda.viana@gmail.com', '(61) 99222-0016'),
(17, '222.333.444-17', 'Gabriel Vasconcelos', 'gabriel.vasc@gmail.com', '(61) 99222-0017'),
(18, '222.333.444-18', 'Helena Maria Brandao', 'helena.brandao@uol.com.br', '(61) 99222-0018'),
(19, '222.333.444-19', 'Igor Teixeira Duarte', 'igor.duarte@gmail.com', NULL),
(20, '222.333.444-20', 'Jessica Aguiar Neves', 'jessica.neves@gmail.com', '(61) 99222-0020'),
(21, '222.333.444-21', 'Kleverton Jose Sales', 'kleverton.sales@gmail.com', '(61) 99222-0021'),
(22, '222.333.444-22', 'Larissa Machado Reis', 'larissa.reis@hotmail.com', '(61) 99222-0022'),
(23, '222.333.444-23', 'Marcelo Antunes Correa', 'marcelo.correa@gmail.com', '(61) 99222-0023'),
(24, '222.333.444-24', 'Natalia Siqueira Franco', 'natalia.franco@gmail.com', '(61) 99222-0024'),
(25, '222.333.444-25', 'Otavio Augusto Bueno', 'otavio.bueno@outlook.com', '(61) 99222-0025'),
(26, '222.333.444-26', 'Paula Renata Peixoto', 'paula.peixoto@gmail.com', NULL),
(27, '222.333.444-27', 'Renato Garcia Mendonca', 'renato.mendonca@gmail.com', '(61) 99222-0027'),
(28, '222.333.444-28', 'Sabrina Talarico Maia', 'sabrina.maia@gmail.com', '(61) 99222-0028'),
(29, '222.333.444-29', 'Thiago Borges Araujo', 'thiago.araujo@gmail.com', '(61) 99222-0029'),
(30, '222.333.444-30', 'Vanessa Cristina Campos', 'vanessa.campos@yahoo.com', '(61) 99222-0030'),
(31, '222.333.444-31', 'Wagner Silva Prado', 'wagner.prado@gmail.com', '(61) 99222-0031'),
(32, '222.333.444-32', 'Yasmin Figueiredo Melo', 'yasmin.melo@gmail.com', NULL),
(33, '222.333.444-33', 'Zaidan Castro Nunes', 'zaidan.nunes@gmail.com', '(61) 99222-0033'),
(34, '222.333.444-34', 'Arthur Pendelton Rios', 'arthur.rios@gmail.com', '(61) 99222-0034'),
(35, '222.333.444-35', 'Bianca Cordreiro Luz', 'bianca.luz@gmail.com', '(61) 99222-0035'),
(36, '222.333.444-36', 'Caio Vinicius Meireles', 'caio.meireles@gmail.com', '(61) 99222-0036'),
(37, '222.333.444-37', 'Debora Esteves Paiva', 'debora.paiva@gmail.com', '(61) 99222-0037'),
(38, '222.333.444-38', 'Erick Breno Fernandes', 'erick.fernandes@gmail.com', NULL),
(39, '222.333.444-39', 'Flavia Alessandra Sobral', 'flavia.sobral@gmail.com', '(61) 99222-0039'),
(40, '222.333.444-40', 'Gustavo Henrique Leal', 'gustavo.leal@gmail.com', '(61) 99222-0040'),
(41, '222.333.444-41', 'Hellen Cristina Matos', 'hellen.matos@gmail.com', '(61) 99222-0041'),
(42, '222.333.444-42', 'Ismael David Diniz', 'ismael.diniz@gmail.com', '(61) 99222-0042'),
(43, '222.333.444-43', 'Janaina Tavares Andrade', 'janaina.andrade@gmail.com', '(61) 99222-0043'),
(44, '222.333.444-44', 'Luan Felipe Maciel', 'luan.maciel@gmail.com', NULL),
(45, '222.333.444-45', 'Mirella Santos Cavalcante', 'mirella.cavalcante@gmail.com', '(61) 99222-0045'),
(46, '222.333.444-46', 'Natan Rodrigues Barreto', 'natan.barreto@gmail.com', '(61) 99222-0046'),
(47, '222.333.444-47', 'Olivia Fontes Medeiros', 'olivia.medeiros@gmail.com', '(61) 99222-0047'),
(48, '222.333.444-48', 'Pedro Henrique Alcantara', 'pedro.alcantara@gmail.com', '(61) 99222-0048'),
(49, '222.333.444-49', 'Quezia Regina Siqueira', 'quezia.siqueira@gmail.com', '(61) 99222-0049'),
(50, '222.333.444-50', 'Rafael Bittencourt Luz', 'rafael.luz@gmail.com', '(61) 99222-0050');

-- ============================================================
-- 2. POVOAMENTO DA TABELA CLIENTE (40 registros)
-- ============================================================
INSERT INTO CLIENTE (id_cliente, data_cadastro, id_pessoa) VALUES
(1, '2022-01-15', 11), (2, '2022-02-10', 12), (3, '2022-03-05', 13), (4, '2022-03-20', 14),
(5, '2022-04-12', 15), (6, '2022-05-18', 16), (7, '2022-06-01', 17), (8, '2022-07-22', 18),
(9, '2022-08-30', 19), (10, '2022-09-14', 20), (11, '2022-10-05', 21), (12, '2022-11-19', 22),
(13, '2022-12-01', 23), (14, '2023-01-10', 24), (15, '2023-02-14', 25), (16, '2023-03-22', 26),
(17, '2023-04-05', 27), (18, '2023-05-12', 28), (19, '2023-06-30', 29), (20, '2023-07-15', 30),
(21, '2023-08-20', 31), (22, '2023-09-10', 32), (23, '2023-10-01', 33), (24, '2023-11-05', 34),
(25, '2023-12-12', 35), (26, '2024-01-08', 36), (27, '2024-02-15', 37), (28, '2024-03-01', 38),
(29, '2024-03-20', 39), (30, '2024-04-10', 40), (31, '2024-05-02', 41), (32, '2024-05-18', 42),
(33, '2024-06-05', 43), (34, '2024-06-25', 44), (35, '2024-07-01', 45), (36, '2024-07-15', 46),
(37, '2024-08-02', 47), (38, '2024-08-10', 48), (39, '2024-08-20', 49), (40, '2024-08-25', 50);

-- ============================================================
-- 3. POVOAMENTO DA TABELA FUNCIONARIO (10 registros)
-- ============================================================
INSERT INTO FUNCIONARIO (id_funcionario, cargo, data_admissao, salario_base, id_gerente, id_pessoa) VALUES
-- Gerentes (id_gerente NULL)
(1, 'Gerente', '2020-01-15', 8500.00, NULL, 1),
(2, 'Gerente', '2021-03-10', 8200.00, NULL, 2),
-- Atendentes (id_gerente supervisor 1 ou 2)
(3, 'Atendente', '2022-05-01', 3200.00, 1, 3),
(4, 'Atendente', '2022-08-15', 3100.00, 1, 4),
(5, 'Atendente', '2023-02-01', 3000.00, 2, 5),
-- Técnicos (obrigatório id_gerente)
(6, 'Tecnico', '2021-06-01', 4800.00, 1, 6),
(7, 'Tecnico', '2021-11-20', 4600.00, 1, 7),
(8, 'Tecnico', '2022-02-10', 4500.00, 2, 8),
(9, 'Tecnico', '2022-09-01', 4300.00, 2, 9),
(10, 'Tecnico', '2023-01-10', 4100.00, 2, 10);

-- ============================================================
-- 4. POVOAMENTO DA TABELA EQUIPAMENTO (45 registros)
-- ============================================================
INSERT INTO EQUIPAMENTO (id_equipamento, tipo_aparelho, marca, modelo, numero_serie, id_cliente) VALUES
(1, 'Notebook', 'Dell', 'Inspiron 15 3000', 'SN-DELL-00192', 1),
(2, 'Smartphone', 'Apple', 'iPhone 11 64GB', 'SN-AAPL-99182', 1),
(3, 'Notebook', 'Lenovo', 'IdeaPad 3', NULL, 2), 
(4, 'Desktop', 'Custom', 'Core i7 10700K', NULL, 3), 
(5, 'Smartphone', 'Samsung', 'Galaxy S21', 'SN-SAMS-44821', 4),
(6, 'Tablet', 'Apple', 'iPad Air 4', 'SN-AAPL-33211', 5),
(7, 'Notebook', 'Acer', 'Nitro 5', 'SN-ACER-88123', 6),
(8, 'Console', 'Sony', 'PlayStation 5', 'SN-SONY-00129', 7),
(9, 'Smartphone', 'Xiaomi', 'Redmi Note 11', NULL, 8),
(10, 'Notebook', 'HP', 'Pavilion 14', 'SN-HP-77123', 9),
(11, 'Desktop', 'Dell', 'Vostro 3681', 'SN-DELL-44102', 10),
(12, 'Smartphone', 'Apple', 'iPhone 13', 'SN-AAPL-10928', 11),
(13, 'Notebook', 'Asus', 'Vivobook 15', 'SN-ASUS-99210', 12),
(14, 'Console', 'Microsoft', 'Xbox Series X', 'SN-MSFT-44192', 13),
(15, 'Smartphone', 'Samsung', 'Galaxy A53', NULL, 14),
(16, 'Notebook', 'Apple', 'MacBook Air M1', 'SN-AAPL-77612', 15),
(17, 'Tablet', 'Samsung', 'Galaxy Tab S7', 'SN-SAMS-11209', 16),
(18, 'Desktop', 'Custom', 'Ryzen 5 5600X', NULL, 17),
(19, 'Notebook', 'Dell', 'G15 5511', 'SN-DELL-55912', 18),
(20, 'Smartphone', 'Motorola', 'Edge 30', 'SN-MOTO-33219', 19),
(21, 'Notebook', 'Lenovo', 'ThinkPad E14', 'SN-LENV-88219', 20),
(22, 'Console', 'Nintendo', 'Switch OLED', 'SN-NINT-10928', 21),
(23, 'Smartphone', 'Apple', 'iPhone 12 Pro', 'SN-AAPL-88301', 22),
(24, 'Notebook', 'Samsung', 'Book E30', NULL, 23),
(25, 'Desktop', 'HP', 'ProDesk 400', 'SN-HP-00192', 24),
(26, 'Smartphone', 'Xiaomi', 'Poco X5 Pro', 'SN-XIAO-99120', 25),
(27, 'Notebook', 'Acer', 'Aspire 5', 'SN-ACER-11029', 26),
(28, 'Tablet', 'Apple', 'iPad 9a Geracao', 'SN-AAPL-55102', 27),
(29, 'Console', 'Sony', 'PlayStation 4 Pro', 'SN-SONY-99201', 28),
(30, 'Smartphone', 'Samsung', 'Galaxy S22 Ultra', 'SN-SAMS-88319', 29),
(31, 'Notebook', 'Dell', 'Latitude 3420', 'SN-DELL-77210', 30),
(32, 'Desktop', 'Custom', 'Core i5 12400F', NULL, 31),
(33, 'Smartphone', 'Apple', 'iPhone 14', 'SN-AAPL-00491', 32),
(34, 'Notebook', 'Lenovo', 'Legion 5', 'SN-LENV-44910', 33),
(35, 'Tablet', 'Lenovo', 'Tab P11 Plus', NULL, 34),
(36, 'Smartphone', 'Motorola', 'Moto G82', 'SN-MOTO-11029', 35),
(37, 'Notebook', 'Asus', 'TUF Gaming F15', 'SN-ASUS-33819', 36),
(38, 'Desktop', 'Dell', 'OptiPlex 3080', 'SN-DELL-88201', 37),
(39, 'Console', 'Microsoft', 'Xbox Series S', 'SN-MSFT-10923', 38),
(40, 'Smartphone', 'Samsung', 'Galaxy Z Flip 4', 'SN-SAMS-99012', 39),
(41, 'Notebook', 'Apple', 'MacBook Pro 13', 'SN-AAPL-44129', 40),
(42, 'Smartphone', 'Apple', 'iPhone XR', NULL, 1), 
(43, 'Notebook', 'Lenovo', 'IdeaPad Gaming 3', 'SN-LENV-10293', 5), 
(44, 'Desktop', 'Custom', 'Ryzen 7 5700X', NULL, 10), 
(45, 'Smartphone', 'Samsung', 'Galaxy A32', 'SN-SAMS-55192', 15);

-- ============================================================
-- 5. POVOAMENTO DA TABELA SERVICO_CATALOGO (10 registros)
-- ============================================================
INSERT INTO SERVICO_CATALOGO (id_servico, nome_servico, preco_base, tempo_estimado_min) VALUES
(1, 'Formatacao e Reinstalacao de Sistema Operacional', 150.00, 120),
(2, 'Troca de Tela de Notebook ou Smartphone', 200.00, 90),
(3, 'Limpeza Interna e Troca de Pasta Termica', 180.00, 60),
(4, 'Diagnostico Tecnico Especializado', 90.00, 45),
(5, 'Reparo Avançado de Placa Mãe / Solda BGA', 450.00, 240),
(6, 'Troca de Bateria Interna', 120.00, 40),
(7, 'Substituicao de Conector de Carga USB/Type-C', 130.00, 60),
(8, 'Upgrade e Instalacao de Memoria RAM ou SSD', 100.00, 45),
(9, 'Desoxidação e Tratamento de Placa Molhada', 250.00, 180),
(10, 'Recuperacao Logica de Dados em HD/SSD', 350.00, 150);

-- ============================================================
-- 6. POVOAMENTO DA TABELA PECA (12 registros)
-- ============================================================
INSERT INTO PECA (id_peca, descricao_peca, preco_custo, preco_venda, qtd_estoque, qtd_minima) VALUES
(1, 'SSD NVMe M.2 512GB Kingston', 180.00, 320.00, 60, 5),
(2, 'Memoria RAM DDR4 8GB 3200MHz Notebook', 110.00, 210.00, 50, 5),
(3, 'Memoria RAM DDR4 16GB 3200MHz Desktop', 200.00, 380.00, 40, 5),
(4, 'Tela LED 15.6 Full HD Slim 30 Pinos', 280.00, 480.00, 25, 3),
(5, 'Bateria Dell Inspiron 15 Series', 150.00, 290.00, 20, 2),
(6, 'Pasta Termica Noctua NT-H1 3.5g', 25.00, 60.00, 100, 10),
(7, 'Display OLED Samsung Galaxy S21', 400.00, 700.00, 15, 2),
(8, 'Bateria Apple iPhone 11 Original', 120.00, 250.00, 25, 3),
(9, 'Fonte ATX 600W 80 Plus Bronze Corsar', 210.00, 380.00, 30, 4),
(10, 'Conector Carga USB-C Universal SMD', 8.00, 45.00, 120, 15),
(11, 'Cooler Air CPU Intel/AMD High Performance', 60.00, 130.00, 35, 5),
(12, 'Fonte Carregador Notebook Universal 65W', 55.00, 120.00, 30, 5);

-- ============================================================
-- 7. POVOAMENTO DA TABELA ORDEM_SERVICO (42 registros)
-- ============================================================
INSERT INTO ORDEM_SERVICO
(id_os, id_atendente, id_tecnico, id_cliente, id_equipamento, data_abertura, data_prevista, defeito_relatado, diagnostico_tecnico, status) VALUES
-- Entregues (1-10)
(1, 3, 6, 1, 1, '2024-05-01 09:00:00', '2024-05-03', 'Notebook esquentando muito e desligando sozinho.', 'Acúmulo de poeira e pasta térmica ressecada. Realizada limpeza interna e troca de pasta térmica.', 'Entregue'),
(2, 4, 7, 1, 2, '2024-05-02 10:30:00', '2024-05-04', 'Tela quebrada apos queda de altura.', 'Display trincado. Realizada a substituição do módulo da tela.', 'Entregue'),
(3, 5, 8, 2, 3, '2024-05-05 11:15:00', '2024-05-07', 'Lentidão extrema ao iniciar o sistema.', 'HD com setores defeituosos. Recomendado e instalado SSD 512GB com clone do SO.', 'Entregue'),
(4, 3, 9, 3, 4, '2024-05-08 14:00:00', '2024-05-10', 'Computador não liga, nenhum LED acende.', 'Fonte de alimentação queimada por oscilação na rede. Efetuada a troca da fonte ATX.', 'Entregue'),
(5, 4, 10, 4, 5, '2024-05-10 16:20:00', '2024-05-12', 'Não carrega a bateria, conector folgado.', 'Conector de carga danificado internamente. Realizada a soldagem de novo conector Type-C.', 'Entregue'),
(6, 5, 6, 5, 6, '2024-05-12 08:45:00', '2024-05-14', 'Bateria descarregando em menos de 1 hora.', 'Bateria com ciclo de vida esgotado (32% de saúde). Troca de bateria realizada com sucesso.', 'Entregue'),
(7, 3, 7, 6, 7, '2024-05-15 13:10:00', '2024-05-18', 'Jogos travando e artefatos na tela.', 'Superaquecimento na GPU por falta de manutenção. Limpeza e troca da pasta térmica efetuadas.', 'Entregue'),
(8, 4, 8, 7, 8, '2024-05-18 15:30:00', '2024-05-21', 'PS5 liga e desliga em seguida (LOD).', 'Curto na linha primária da fonte interna. Reparo de placa e substituição de capacitores.', 'Entregue'),
(9, 5, 9, 8, 9, '2024-05-20 09:50:00', '2024-05-22', 'Aparelho caiu na água e parou de dar imagem.', 'Oxidação moderada na placa principal. Realizado banho ultrassônico e desoxidação.', 'Entregue'),
(10, 3, 10, 9, 10, '2024-05-22 11:00:00', '2024-05-25', 'Teclas falhando e SO lento.', 'Teclado danificado e sistema corrompido. Reinstalação limpa do Windows efetuada.', 'Entregue'),
-- Concluidas (11-20)
(11, 4, 6, 10, 11, '2024-06-01 10:00:00', '2024-06-03', 'Computador bipando ao ligar.', 'Pente de memória RAM com defeito. Substituição por módulo DDR4 16GB.', 'Concluido'),
(12, 5, 7, 11, 12, '2024-06-03 14:15:00', '2024-06-05', 'Bateria estufada pressionando a tela.', 'Bateria estufada com risco. Removida e instalada nova bateria original.', 'Concluido'),
(13, 3, 8, 12, 13, '2024-06-05 09:30:00', '2024-06-08', 'Sem som nos alto-falantes e notebook lento.', 'Driver corrompido e necessidade de upgrade de RAM. Adicionado pente de 8GB DDR4.', 'Concluido'),
(14, 4, 9, 13, 14, '2024-06-08 16:45:00', '2024-06-11', 'Xbox esquentando e desligando no meio do jogo.', 'Pasta térmica ressecada e cooler obstruído. Manutenção preventiva realizada.', 'Concluido'),
(15, 5, 10, 14, 15, '2024-06-10 11:20:00', '2024-06-12', 'Tela apagada mas aparelho vibra.', 'Display queimado. Substituição do display efetuada e testada.', 'Concluido'),
(16, 3, 6, 15, 16, '2024-06-12 13:00:00', '2024-06-15', 'Trackpad não clica e bateria viciada.', 'Troca do módulo de bateria estufada que pressionava o trackpad por baixo.', 'Concluido'),
(17, 4, 7, 16, 17, '2024-06-15 15:10:00', '2024-06-17', 'Conector de carga com mau contato.', 'Troca da subplaca de carga efetuada com sucesso.', 'Concluido'),
(18, 5, 8, 17, 18, '2024-06-18 08:30:00', '2024-06-20', 'PC liga mas não dá vídeo.', 'BIOS corrompida. Efetuada a regravação da BIOS via gravador epron externo.', 'Concluido'),
(19, 3, 9, 18, 19, '2024-06-20 10:40:00', '2024-06-22', 'Tela piscando ao mover a dobradiça.', 'Cabo flat do display danificado. Troca do cabo flat por peça nova.', 'Concluido'),
(20, 4, 10, 19, 20, '2024-06-22 14:00:00', '2024-06-24', 'Aparelho travado na tela da logo.', 'Loop infinito no firmware. Reflash de firmware efetuado com sucesso.', 'Concluido'),
-- Em Execução (21-28)
(21, 5, 6, 20, 21, '2024-07-01 09:10:00', '2024-07-05', 'Gargalo em multitarefas e travamentos.', 'Necessidade de limpeza física e upgrade de SSD NVMe.', 'Em Execucao'),
(22, 3, 7, 21, 22, '2024-07-02 11:30:00', '2024-07-04', 'Analogico esquerdo com drift severo.', 'Análise confirma desgaste no trimpot do analógico. Em processo de soldagem de novo componente.', 'Em Execucao'),
(23, 4, 8, 22, 23, '2024-07-03 14:00:00', '2024-07-06', 'Vidro traseiro e bateria precisando de troca.', 'Troca de bateria autorizada. Em execução pelo técnico.', 'Em Execucao'),
(24, 5, 9, 23, 24, '2024-07-04 16:15:00', '2024-07-07', 'Notebook muito lento na inicialização.', 'Diagnostico indica HD com 100% de uso constante. Instalação do SSD em andamento.', 'Em Execucao'),
(25, 3, 10, 24, 25, '2024-07-05 08:50:00', '2024-07-08', 'Gabinete esquentando e desligando repentinamente.', 'Cooler do processador parado. Troca por cooler Air High Performance em andamento.', 'Em Execucao'),
(26, 4, 6, 25, 26, '2024-07-06 10:20:00', '2024-07-09', 'Aparelho não segura carga.', 'Verificada necessidade de substituição de bateria. Reparo em progresso.', 'Em Execucao'),
(27, 5, 7, 26, 27, '2024-07-08 13:40:00', '2024-07-11', 'Tela com linhas verticais coloridas.', 'Falha no painel LED. Instalação de nova tela 15.6 slim em andamento.', 'Em Execucao'),
(28, 3, 8, 27, 28, '2024-07-09 15:00:00', '2024-07-12', 'Sem acesso à rede Wi-Fi e bateria fraca.', 'Substituição da placa de rede interna e bateria.', 'Em Execucao'),
-- Aguardando Peça (29-33)
(29, 4, 9, 28, 29, '2024-07-10 09:00:00', '2024-07-20', 'Leitor de disco não ejeta nem lê jogos.', 'Engrenagem do drive óptico quebrada. Peça encomendada junto ao fornecedor.', 'Aguardando Peca'),
(30, 5, 10, 29, 30, '2024-07-11 11:10:00', '2024-07-22', 'Tela dobrável piscando e falhando toque.', 'Display Z Flip danificado. Aguardando entrega de módulo oficial.', 'Aguardando Peca'),
(31, 3, 6, 30, 31, '2024-07-12 14:30:00', '2024-07-25', 'Placa mãe sem alimentação no circuito de entrada.', 'MOSFETs da linha primária queimados. Aguardando chegada dos componentes SMD.', 'Aguardando Peca'),
(32, 4, 7, 31, 32, '2024-07-13 16:00:00', '2024-07-23', 'Placa de vídeo não reconhece no Windows.', 'Chip gráfico necessita de reballing/substituição do chip. Peça em trânsito.', 'Aguardando Peca'),
(33, 5, 8, 32, 33, '2024-07-15 08:30:00', '2024-07-24', 'Câmera traseira trincada e sem foco.', 'Módulo de câmera danificado. Aguardando fornecedor.', 'Aguardando Peca'),
-- Em Diagnóstico (34-38)
(34, 3, 9, 33, 34, '2024-07-16 10:00:00', '2024-07-19', 'Lentidão e desligamento sem motivo aparente.', 'Em análise bancada para verificar temperaturas e memória.', 'Em Diagnostico'),
(35, 4, 10, 34, 35, '2024-07-17 12:00:00', '2024-07-20', 'Não conecta no Wi-Fi e touch falha.', 'Técnico efetuando testes de continuidade na placa.', 'Em Diagnostico'),
(36, 5, 6, 35, 36, '2024-07-18 14:20:00', '2024-07-21', 'Alto-falante com chiado forte.', 'Em diagnóstico de circuito de áudio.', 'Em Diagnostico'),
(37, 3, 7, 36, 37, '2024-07-19 16:10:00', '2024-07-22', 'Teclado travando algumas letras.', 'Em avaliação para verificar se é sujeira ou falha física da membrana.', 'Em Diagnostico'),
(38, 4, 8, 37, 38, '2024-07-20 09:40:00', NULL, 'Fonte fazendo barulho estranho de zumbido.', 'Análise de capacitores da fonte em andamento.', 'Em Diagnostico'),
-- Aberto (39-42)
(39, 5, NULL, 38, 39, '2024-07-21 11:00:00', NULL, 'Console liga mas fica na tela preta sem sinal HDMI.', NULL, 'Aberto'),
(40, 3, NULL, 39, 40, '2024-07-21 13:30:00', NULL, 'Aparelho desliga ao abrir a câmera.', NULL, 'Aberto'),
(41, 4, 9, 40, 41, '2024-07-22 08:15:00', '2024-07-25', 'Kernel panic constante no macOS.', NULL, 'Aberto'),
(42, 5, NULL, 1, 42, '2024-07-22 10:00:00', NULL, 'Segunda entrada do cliente 1: iPhone XR não liga.', NULL, 'Aberto');

-- ============================================================
-- 8. POVOAMENTO DA TABELA HISTORICO_STATUS_OS (115 registros)
-- ============================================================
INSERT INTO HISTORICO_STATUS_OS (id_os, data_hora, status_novo, id_funcionario) VALUES
-- OS 1 (Entregue)
(1, '2024-05-01 09:00:00', 'Aberto', 3), (1, '2024-05-01 10:30:00', 'Em Diagnostico', 6), (1, '2024-05-01 14:00:00', 'Aguardando Peca', 6),
(1, '2024-05-02 09:15:00', 'Em Execucao', 6), (1, '2024-05-02 16:00:00', 'Concluido', 6), (1, '2024-05-03 11:00:00', 'Entregue', 3),
-- OS 2 (Entregue)
(2, '2024-05-02 10:30:00', 'Aberto', 4), (2, '2024-05-02 11:45:00', 'Em Diagnostico', 7), (2, '2024-05-03 08:30:00', 'Em Execucao', 7),
(2, '2024-05-03 17:00:00', 'Concluido', 7), (2, '2024-05-04 10:00:00', 'Entregue', 4),
-- OS 3 (Entregue)
(3, '2024-05-05 11:15:00', 'Aberto', 5), (3, '2024-05-05 14:00:00', 'Em Diagnostico', 8), (3, '2024-05-06 09:00:00', 'Em Execucao', 8),
(3, '2024-05-06 15:30:00', 'Concluido', 8), (3, '2024-05-07 14:20:00', 'Entregue', 5),
-- OS 4 (Entregue)
(4, '2024-05-08 14:00:00', 'Aberto', 3), (4, '2024-05-08 16:30:00', 'Em Diagnostico', 9), (4, '2024-05-09 10:00:00', 'Em Execucao', 9),
(4, '2024-05-09 17:15:00', 'Concluido', 9), (4, '2024-05-10 09:40:00', 'Entregue', 3),
-- OS 5 (Entregue)
(5, '2024-05-10 16:20:00', 'Aberto', 4), (5, '2024-05-11 09:00:00', 'Em Diagnostico', 10), (5, '2024-05-11 11:30:00', 'Em Execucao', 10),
(5, '2024-05-11 16:45:00', 'Concluido', 10), (5, '2024-05-12 10:15:00', 'Entregue', 4),
-- OS 6 (Entregue)
(6, '2024-05-12 08:45:00', 'Aberto', 5), (6, '2024-05-12 10:00:00', 'Em Diagnostico', 6), (6, '2024-05-13 09:30:00', 'Em Execucao', 6),
(6, '2024-05-13 14:00:00', 'Concluido', 6), (6, '2024-05-14 16:00:00', 'Entregue', 5),
-- OS 7 a 10 (Entregues)
(7, '2024-05-15 13:10:00', 'Aberto', 3), (7, '2024-05-16 09:00:00', 'Em Diagnostico', 7), (7, '2024-05-17 10:00:00', 'Concluido', 7), (7, '2024-05-18 11:30:00', 'Entregue', 3),
(8, '2024-05-18 15:30:00', 'Aberto', 4), (8, '2024-05-19 10:00:00', 'Em Diagnostico', 8), (8, '2024-05-20 14:00:00', 'Concluido', 8), (8, '2024-05-21 09:00:00', 'Entregue', 4),
(9, '2024-05-20 09:50:00', 'Aberto', 5), (9, '2024-05-21 08:30:00', 'Em Diagnostico', 9), (9, '2024-05-21 16:00:00', 'Concluido', 9), (9, '2024-05-22 10:00:00', 'Entregue', 5),
(10, '2024-05-22 11:00:00', 'Aberto', 3), (10, '2024-05-23 09:00:00', 'Em Diagnostico', 10), (10, '2024-05-24 15:00:00', 'Concluido', 10), (10, '2024-05-25 14:00:00', 'Entregue', 3),
-- OS 11 a 20 (Concluídas)
(11, '2024-06-01 10:00:00', 'Aberto', 4), (11, '2024-06-01 14:00:00', 'Em Diagnostico', 6), (11, '2024-06-02 09:00:00', 'Em Execucao', 6), (11, '2024-06-03 11:00:00', 'Concluido', 6),
(12, '2024-06-03 14:15:00', 'Aberto', 5), (12, '2024-06-04 08:30:00', 'Em Diagnostico', 7), (12, '2024-06-04 13:00:00', 'Em Execucao', 7), (12, '2024-06-05 10:00:00', 'Concluido', 7),
(13, '2024-06-05 09:30:00', 'Aberto', 3), (13, '2024-06-06 10:00:00', 'Em Diagnostico', 8), (13, '2024-06-07 09:00:00', 'Em Execucao', 8), (13, '2024-06-08 14:00:00', 'Concluido', 8),
(14, '2024-06-08 16:45:00', 'Aberto', 4), (14, '2024-06-09 09:00:00', 'Em Diagnostico', 9), (14, '2024-06-10 10:30:00', 'Em Execucao', 9), (14, '2024-06-11 11:00:00', 'Concluido', 9),
(15, '2024-06-10 11:20:00', 'Aberto', 5), (15, '2024-06-10 15:00:00', 'Em Diagnostico', 10), (15, '2024-06-11 09:00:00', 'Em Execucao', 10), (15, '2024-06-12 09:30:00', 'Concluido', 10),
(16, '2024-06-12 13:00:00', 'Aberto', 3), (16, '2024-06-13 09:00:00', 'Em Diagnostico', 6), (16, '2024-06-14 10:00:00', 'Em Execucao', 6), (16, '2024-06-15 12:00:00', 'Concluido', 6),
(17, '2024-06-15 15:10:00', 'Aberto', 4), (17, '2024-06-16 08:30:00', 'Em Diagnostico', 7), (17, '2024-06-16 14:00:00', 'Em Execucao', 7), (17, '2024-06-17 15:00:00', 'Concluido', 7),
(18, '2024-06-18 08:30:00', 'Aberto', 5), (18, '2024-06-18 11:00:00', 'Em Diagnostico', 8), (18, '2024-06-19 10:00:00', 'Em Execucao', 8), (18, '2024-06-20 16:30:00', 'Concluido', 8),
(19, '2024-06-20 10:40:00', 'Aberto', 3), (19, '2024-06-21 09:00:00', 'Em Diagnostico', 9), (19, '2024-06-21 15:00:00', 'Em Execucao', 9), (19, '2024-06-22 11:30:00', 'Concluido', 9),
(20, '2024-06-22 14:00:00', 'Aberto', 4), (20, '2024-06-23 09:00:00', 'Em Diagnostico', 10), (20, '2024-06-23 16:00:00', 'Em Execucao', 10), (20, '2024-06-24 10:00:00', 'Concluido', 10),
-- OS 21 a 28 (Em Execução)
(21, '2024-07-01 09:10:00', 'Aberto', 5), (21, '2024-07-01 14:00:00', 'Em Diagnostico', 6), (21, '2024-07-02 09:00:00', 'Em Execucao', 6),
(22, '2024-07-02 11:30:00', 'Aberto', 3), (22, '2024-07-02 15:00:00', 'Em Diagnostico', 7), (22, '2024-07-03 10:00:00', 'Em Execucao', 7),
(23, '2024-07-03 14:00:00', 'Aberto', 4), (23, '2024-07-04 09:00:00', 'Em Diagnostico', 8), (23, '2024-07-04 14:30:00', 'Em Execucao', 8),
(24, '2024-07-04 16:15:00', 'Aberto', 5), (24, '2024-07-05 08:30:00', 'Em Diagnostico', 9), (24, '2024-07-05 11:00:00', 'Em Execucao', 9),
(25, '2024-07-05 08:50:00', 'Aberto', 3), (25, '2024-07-05 13:00:00', 'Em Diagnostico', 10), (25, '2024-07-06 09:00:00', 'Em Execucao', 10),
(26, '2024-07-06 10:20:00', 'Aberto', 4), (26, '2024-07-06 14:00:00', 'Em Diagnostico', 6), (26, '2024-07-07 10:00:00', 'Em Execucao', 6),
(27, '2024-07-08 13:40:00', 'Aberto', 5), (27, '2024-07-09 09:00:00', 'Em Diagnostico', 7), (27, '2024-07-09 15:00:00', 'Em Execucao', 7),
(28, '2024-07-09 15:00:00', 'Aberto', 3), (28, '2024-07-10 08:30:00', 'Em Diagnostico', 8), (28, '2024-07-10 11:30:00', 'Em Execucao', 8),
-- OS 29 a 33 (Aguardando Peça)
(29, '2024-07-10 09:00:00', 'Aberto', 4), (29, '2024-07-10 11:00:00', 'Em Diagnostico', 9), (29, '2024-07-11 09:30:00', 'Aguardando Peca', 9),
(30, '2024-07-11 11:10:00', 'Aberto', 5), (30, '2024-07-11 15:00:00', 'Em Diagnostico', 10), (30, '2024-07-12 10:00:00', 'Aguardando Peca', 10),
(31, '2024-07-12 14:30:00', 'Aberto', 3), (31, '2024-07-13 09:00:00', 'Em Diagnostico', 6), (31, '2024-07-13 14:00:00', 'Aguardando Peca', 6),
(32, '2024-07-13 16:00:00', 'Aberto', 4), (32, '2024-07-14 10:00:00', 'Em Diagnostico', 7), (32, '2024-07-14 16:30:00', 'Aguardando Peca', 7),
(33, '2024-07-15 08:30:00', 'Aberto', 5), (33, '2024-07-15 11:30:00', 'Em Diagnostico', 8), (33, '2024-07-16 09:00:00', 'Aguardando Peca', 8),
-- OS 34 a 38 (Em Diagnóstico)
(34, '2024-07-16 10:00:00', 'Aberto', 3), (34, '2024-07-16 14:00:00', 'Em Diagnostico', 9),
(35, '2024-07-17 12:00:00', 'Aberto', 4), (35, '2024-07-17 15:30:00', 'Em Diagnostico', 10),
(36, '2024-07-18 14:20:00', 'Aberto', 5), (36, '2024-07-19 09:00:00', 'Em Diagnostico', 6),
(37, '2024-07-19 16:10:00', 'Aberto', 3), (37, '2024-07-20 08:30:00', 'Em Diagnostico', 7),
(38, '2024-07-20 09:40:00', 'Aberto', 4), (38, '2024-07-20 11:00:00', 'Em Diagnostico', 8),
-- OS 39 a 42 (Aberto)
(39, '2024-07-21 11:00:00', 'Aberto', 5),
(40, '2024-07-21 13:30:00', 'Aberto', 3),
(41, '2024-07-22 08:15:00', 'Aberto', 4),
(42, '2024-07-22 10:00:00', 'Aberto', 5);

-- ============================================================
-- 9. POVOAMENTO DA TABELA POSSUI_SERVICO (60 registros)
-- ============================================================
INSERT INTO POSSUI_SERVICO (id_servico, id_os, quantidade, preco_praticado) VALUES
(3, 1, 1, 180.00),
(2, 2, 1, 200.00),
(1, 3, 1, 150.00), (8, 3, 1, 100.00),
(4, 4, 1, 90.00),
(7, 5, 1, 130.00),
(6, 6, 1, 120.00),
(3, 7, 1, 180.00),
(5, 8, 1, 450.00),
(9, 9, 1, 250.00),
(1, 10, 1, 150.00),
(4, 11, 1, 90.00), (8, 11, 1, 100.00),
(6, 12, 1, 120.00),
(8, 13, 1, 100.00),
(3, 14, 1, 180.00),
(2, 15, 1, 200.00),
(6, 16, 1, 120.00),
(7, 17, 1, 130.00),
(5, 18, 1, 450.00),
(2, 19, 1, 200.00),
(1, 20, 1, 150.00),
(3, 21, 1, 180.00), (8, 21, 1, 100.00),
(5, 22, 1, 450.00),
(6, 23, 1, 120.00),
(8, 24, 1, 100.00),
(3, 25, 1, 180.00),
(6, 26, 1, 120.00),
(2, 27, 1, 200.00),
(6, 28, 1, 120.00),
(5, 29, 1, 450.00),
(2, 30, 1, 200.00),
(5, 31, 1, 450.00),
(5, 32, 1, 450.00),
(2, 33, 1, 200.00),
(4, 34, 1, 90.00),
(4, 35, 1, 90.00),
(4, 36, 1, 90.00),
(4, 37, 1, 90.00),
(4, 38, 1, 90.00),
(1, 2, 1, 150.00),
(3, 3, 1, 180.00),
(10, 3, 1, 350.00),
(3, 5, 1, 180.00),
(1, 7, 1, 150.00),
(3, 11, 1, 180.00),
(1, 13, 1, 150.00),
(1, 16, 1, 150.00),
(3, 19, 1, 180.00),
(1, 21, 1, 150.00),
(1, 24, 1, 150.00),
(8, 25, 1, 100.00),
(1, 27, 1, 150.00),
(8, 28, 1, 100.00),
(4, 29, 1, 90.00),
(4, 30, 1, 90.00),
(4, 31, 1, 90.00),
(4, 32, 1, 90.00),
(4, 33, 1, 90.00);

-- ============================================================
-- 10. POVOAMENTO DA TABELA UTILIZA_PECA (55 registros)
-- ============================================================
-- Cumpre RN17, RN18, RN19:
-- A inserção nesta tabela dispara a trigger que abate
-- a quantidade de peças automaticamente de PECA.qtd_estoque.
-- Distribuição alinhada com as ordens de serviço executadas e entregues.
INSERT INTO UTILIZA_PECA (id_peca, id_os, quantidade, preco_praticado) VALUES
(6, 1, 1, 60.00),
(2, 1, 1, 210.00),
(4, 2, 1, 480.00),
(8, 2, 1, 250.00),
(1, 3, 1, 320.00),
(2, 3, 1, 210.00),
(6, 3, 1, 60.00),
(1, 4, 1, 320.00),
(10, 5, 1, 45.00),
(8, 5, 1, 250.00),
(8, 6, 1, 250.00),
(10, 6, 1, 45.00),
(6, 7, 1, 60.00),
(2, 7, 1, 210.00),
(1, 7, 1, 320.00),
(6, 8, 1, 60.00),
(10, 8, 1, 45.00),
(10, 9, 1, 45.00),
(8, 9, 1, 250.00),
(1, 10, 1, 320.00),
(6, 10, 1, 60.00),
(3, 11, 1, 380.00),
(6, 11, 1, 60.00),
(8, 12, 1, 250.00),
(10, 12, 1, 45.00),
(2, 13, 1, 210.00),
(6, 13, 1, 60.00),
(6, 14, 1, 60.00),
(10, 14, 1, 45.00),
(7, 15, 1, 700.00),
(8, 15, 1, 250.00),
(5, 16, 1, 290.00),
(2, 16, 1, 210.00),
(10, 17, 1, 45.00),
(8, 17, 1, 250.00),
(6, 18, 1, 60.00),
(3, 18, 1, 380.00),
(4, 19, 1, 480.00),
(2, 19, 1, 210.00),
(10, 20, 1, 45.00),
(8, 20, 1, 250.00),
(1, 21, 1, 320.00),
(6, 21, 1, 60.00),
(10, 22, 1, 45.00),
(6, 22, 1, 60.00),
(8, 23, 1, 250.00),
(10, 23, 1, 45.00),
(1, 24, 1, 320.00),
(2, 24, 1, 210.00),
(11, 25, 1, 130.00),
(6, 25, 1, 60.00),
(8, 26, 1, 250.00),
(4, 27, 1, 480.00),
(8, 28, 1, 250.00),
(12, 29, 1, 120.00);