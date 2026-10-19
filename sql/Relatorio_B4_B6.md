# SGATM – Parte B4 (Otimização de Consultas) e B6 (Auditoria e Gatilhos)

Banco: MySQL 8.0 – Laboratório de Banco de Dados (UCB)

## B4 – Otimização de consultas

### Metodologia
A carga oficial (`02_carga.sql`) tem só 42 OSs; com tão poucas linhas o MySQL varre a tabela inteira e índice nenhum muda o resultado. Por isso foi criado o banco `sgatm_perf` (script `04a_massa_volume.sql`) com a mesma estrutura e volume maior: 300 mil OSs, 1,08 milhão de eventos de histórico, 450 mil serviços e 400 mil peças em OSs. O banco oficial `sgatm_db` não é alterado, exceto pela criação dos índices no final.

Medição: `EXPLAIN` (plano de execução) e `EXPLAIN ANALYZE` (tempo real, em ms), antes e depois dos índices (`04_otimizacao.sql`).

### Consultas críticas escolhidas
| Consulta | Pergunta de negócio | Por que é crítica |
|---|---|---|
| C08 | Clientes com mais de 1 OS | Junta ORDEM_SERVICO com CLIENTE e agrupa por cliente |
| C09 | OS finalizadas por técnico | Filtra por status e agrupa por técnico |
| C14 | Tempo médio de resolução por técnico (SLA) | Duas agregações sobre a tabela que mais cresce (histórico) |

### Índices criados
| Índice | Tabela | Consulta |
|---|---|---|
| `idx_os_cliente (id_cliente)` | ORDEM_SERVICO | C08 |
| `idx_os_tecnico_status (id_tecnico, status)` | ORDEM_SERVICO | C09 |
| `idx_hist_os_status_data (id_os, status_novo, data_hora)` | HISTORICO_STATUS_OS | C14 |

### Plano de execução (EXPLAIN)
| Consulta | Antes | Depois |
|---|---|---|
| C08 | OS lida pelo índice `idx_os_equip_cli` (297.861 linhas, índice inadequado) | OS acessada por `idx_os_cliente` (`ref`, "Using index") |
| C09 | OS acessada por `idx_os_tecnico`, precisa ler a tabela ("Using where") | `idx_os_tecnico_status`, "Using where; **Using index**" (índice cobre a consulta, não lê a tabela) |
| C14 | Histórico lido pelo índice de FK `fk_historico_os` (1,08 mi linhas, volta à tabela para ler `data_hora`/`status_novo`) | `idx_hist_os_status_data`, "**Using index**" nas duas subconsultas |

### Ganho de desempenho (EXPLAIN ANALYZE, tempo total)
| Consulta | Antes | Depois | Ganho |
|---|---|---|---|
| C08 | 2.008 ms | 1.391 ms | 1,4x (≈31% menor) |
| C09 | 1.267 ms | 241 ms | 5,3x (≈81% menor) |
| C14 | 20.216 ms | 4.193 ms | 4,8x (≈79% menor) |

Observações honestas:
- O ganho em C08 é modesto porque o resultado devolve 60 mil clientes e o custo maior está em agrupar e ordenar, não em achar as linhas. O índice ainda é útil para qualquer busca por cliente (ex.: "OSs do cliente X"), que hoje não tinha índice.
- Os tempos variam de máquina para máquina e de execução para execução; o que importa é a proporção antes/depois.
- `idx_os_tecnico` passa a ser redundante (prefixo de `idx_os_tecnico_status`) e poderia ser removido para reduzir custo de escrita; foi mantido para não alterar o DDL original.
- Índices custam espaço e deixam INSERT/UPDATE um pouco mais lentos; por isso só foram criados para as consultas críticas.
- A consulta C13 (11 s no volume testado) não melhora com índice: o gargalo são subconsultas que agregam POSSUI_SERVICO e UTILIZA_PECA inteiras. Ela exigiria reescrita da consulta, não novo índice.

## B6 – Tabela de auditoria e gatilhos (`05_auditoria.sql`)

### Tabela AUDITORIA
Campos: `id_auditoria`, `tabela_afetada`, `operacao` (UPDATE/DELETE), `id_registro`, `campo_alterado`, `valor_anterior`, `valor_novo`, `usuario_banco` (conta MySQL, via `USER()`), `data_hora`.
Sem FOREIGN KEY de propósito: o registro de auditoria de uma linha excluída precisa continuar existindo. Imutável (triggers bloqueiam UPDATE/DELETE), seguindo a mesma ideia da RN13.

### Alterações críticas auditadas
| Tabela | Evento | O que é registrado |
|---|---|---|
| FUNCIONARIO | UPDATE / DELETE | salário, cargo, supervisor |
| PECA | UPDATE / DELETE | preço de custo e de venda |
| SERVICO_CATALOGO | UPDATE | preço base |
| ORDEM_SERVICO | UPDATE | técnico, data prevista, diagnóstico (status já está no histórico, RN12) |
| POSSUI_SERVICO / UTILIZA_PECA | UPDATE / DELETE | quantidade e preço praticado (valor cobrado do cliente) |

Um `UPDATE` que muda dois campos gera dois registros; um `UPDATE` que não muda campo auditado não gera nenhum. `qtd_estoque` não é auditada, pois muda a cada peça usada (RN18/RN19) e geraria ruído.

### Triggers (13) e procedimento
`sp_registrar_auditoria` (procedimento que centraliza o INSERT) e os triggers `trg_aud_funcionario_upd/del`, `trg_aud_peca_upd/del`, `trg_aud_servico_catalogo_upd`, `trg_aud_os_upd`, `trg_aud_possui_servico_upd/del`, `trg_aud_utiliza_peca_upd/del`, `trg_auditoria_imutavel_upd/del`.

### Testes executados (seção 10 do script)
T1 reajuste de salário → 1 registro; T2 preço de peça (custo e venda) → 2 registros; T3 preço de serviço → 1; T4 troca de técnico e data prevista da OS 21 → 2; T5 preço praticado em OS → 1; T6 UPDATE sem mudança em campo auditado → 0; T7 remoção de peça de uma OS → 1 (e estoque devolvido pela RN19); T8 tentativa de alterar/excluir AUDITORIA → erro 45000. Os testes rodam em transação com ROLLBACK, então a carga não é alterada.

## Ordem de execução
`01_ddl.sql` → `02_carga.sql` → `03_consultas.sql` → `05_auditoria.sql` → `04a_massa_volume.sql` → `04_otimizacao.sql`
