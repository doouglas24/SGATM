# SGATM - Sistema de Gerenciamento de Assistência Técnica e Manutenção

Projeto acadêmico desenvolvido para a disciplina de **Laboratório de Banco de Dados** (2026/2) da Universidade Católica de Brasília (UCB).

## Tema e Escopo
O SGATM é um banco de dados projetado para gerenciar as operações de uma oficina de assistência técnica e manutenção de equipamentos. O sistema controla o cadastro de clientes, colaboradores (técnicos e atendentes), ordens de serviço, serviços prestados, peças utilizadas e o histórico de status de cada atendimento.

## Divisão de Papéis e Responsabilidades
| Integrante | Papel no Projeto | Principais Contribuições |
| :--- | :--- | :--- |
| **Michael Douglas Mendes Costa** | Administrador do Banco (DBA) & Modelador Principal | Mapeamento dos modelos ER/Lógico, implementação dos scripts DDL (`01_ddl.sql`), carga de dados (`02_carga.sql`), consultas SQL (`03_consultas.sql`) e consolidação do relatório. |
| **Maria Rosa Magalhães** | Analista de Domínio | Levantamento das regras de negócio (RN01 a RN20), documentação do escopo do sistema SGATM e auxílio no dicionário de dados. |
| **Lorena Dalmagro** | Analista de Negócios e Documentação | Revisão textual do relatório, verificação de consistência entre escopo e dicionário, e preparação dos materiais para a apresentação oral. |
| **Miguel Araújo de Melo** | Apoio de Modelagem e Testes | Auxílio na revisão dos diagramas conceituais/lógicos e testes de validação do script DDL e das consultas. |
| **Mateus Elias Pereira Soares** | Apoio de Testes e Apresentação | Verificação das restrições do banco de dados, auxílio no roteiro de testes da carga de dados e suporte na montagem da apresentação oral. |

## Tecnologias Utilizadas
* **SGBD:** MySQL 8.0+
* **Codificação de Caracteres:** `utf8mb4`
* **Ferramentas de Modelagem:** draw.io e MySQL Workbench

## Estrutura do Repositório
* `docs/`: Documentação textual, modelos conceituais/lógicos e dicionário de dados em PDF.
* `sql/`:
  * `01_ddl.sql`: Script de criação das tabelas, triggers e views do banco.
  * `02_carga.sql`: Script com a massa de dados para testes.
  * `03_consultas.sql`: Script com as 15 consultas de verificação.

## Como Executar o Banco de Dados
1. Abra o ambiente MySQL (Terminal ou MySQL Workbench).
2. Execute o script `sql/01_ddl.sql` para criar o banco de dados `sgatm` e suas estruturas.
3. Execute o script `sql/02_carga.sql` para popular as tabelas com os dados de teste.
4. Execute as consultas presentes em `sql/03_consultas.sql` para validar o funcionamento das buscas.
