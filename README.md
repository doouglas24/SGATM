# SGATM - Sistema de Gerenciamento de Assistência Técnica e Manutenção

Projeto acadêmico desenvolvido para a disciplina de **Laboratório de Banco de Dados** (2026/2) da Universidade Católica de Brasília (UCB).

## Tema e Escopo
O SGATM é um banco de dados projetado para gerenciar as operações de uma oficina de assistência técnica e manutenção de equipamentos. O sistema controla o cadastro de clientes, colaboradores (técnicos e atendentes), ordens de serviço, serviços prestados, peças utilizadas e o histórico de status de cada atendimento.

##  Integrantes da Equipe
* **Michael Douglas Mendes Costa** - [michael.dcosta@a.ucb.br](mailto:michael.dcosta@a.ucb.br) | [@doouglas24](https://github.com/doouglas24)
* **Maria Rosa Magalhães Brasileiro** - [maria.brasileiro@a.ucb.br](mailto:maria.brasileiro@a.ucb.br) | [@mariarosambrasileiro07](https://github.com/mariarosambrasileiro07)
* **Nome do Integrante 3** - [email@a.ucb.br](mailto:email@a.ucb.br) | [@usuario3](https://github.com/usuario3)
* **Nome do Integrante 4** - [email@a.ucb.br](mailto:email@a.ucb.br) | [@usuario4](https://github.com/usuario4)
## Tecnologias Utilizadas
* **SGBD:** MySQL 8.0+
* **Codificação de Caracteres:** `utf8mb4`
* **Ferramenta de Modelagem:** [Ex: MySQL Workbench / draw.io]

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
