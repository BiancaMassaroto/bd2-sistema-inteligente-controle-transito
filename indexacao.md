# Indexação (MySQL)

Análise das consultas mais importantes do sistema e dos índices criados para acelerá-las. Os comandos estão em `mysql/indices.sql`.

## 1. Índices que já existem

- **Chaves primárias:** o MySQL cria um índice para cada PK automaticamente.
- **Chaves estrangeiras:** o InnoDB também cria um índice para cada coluna de FK (por exemplo, `registro_infracao.iddispositivo` e `local.idcidade`). Por isso não criamos índices separados para elas.

Os índices abaixo são os **criados pelo grupo**, para colunas que aparecem em `WHERE`, `GROUP BY` e `ORDER BY` das consultas mais usadas e que não são cobertas pelas chaves.

## 2. Colunas candidatas à indexação

| Coluna | Onde aparece | Candidata? |
|---|---|---|
| `registro_infracao.data_infracao`, `horario_infracao` | Filtro por período, ordenação das mais recentes, infrações por mês e horário | Sim |
| `registro_infracao.placa_veiculo` | Busca de infrações de um mesmo veículo | Sim |
| `dispositivo.tipo`, `ativo` | Contagem por tipo e filtro de inativos | Sim (em conjunto) |
| `evento_trafego.tipo` | Tipos de evento mais frequentes (`GROUP BY tipo`) | Sim |
| `local.bairro` | Agrupamentos e filtros por bairro | Sim |
| `fluxo_trafego.id_dispositivo`, `velocidade_media`, `qtd_veiculos` | Somas e médias por dispositivo | Sim (índice de cobertura) |
| `dispositivo.ativo` sozinho | Filtro de inativos | **Não**: só tem 2 valores (0 e 1), então o índice seria pouco seletivo e o otimizador tende a ignorá-lo. Por isso entra combinado com `tipo`. |
| `fluxo_trafego.id_fluxo` em `HOUR(id_fluxo)` | Congestionamento por horário | **Não**: aplicar função na coluna impede o uso do índice. |

## 3. Índices criados e justificativas

| # | Índice | Tabela (colunas) | Justificativa |
|---|---|---|---|
| 1 | `idx_infracao_data_hora` | `registro_infracao (data_infracao, horario_infracao)` | Infrações é uma das tabelas que mais cresce. O índice composto atende filtros por período e a ordenação das mais recentes sem ordenar a tabela inteira. |
| 2 | `idx_infracao_placa` | `registro_infracao (placa_veiculo)` | A placa tem alta seletividade (poucas infrações por placa). A busca passa de varrer toda a tabela para ir direto às linhas da placa. |
| 3 | `idx_dispositivos_tipo_ativo` | `dispositivo (tipo, ativo)` | Atende contagem por tipo e filtros que combinam tipo e situação. A ordem tipo + ativo evita o problema da baixa seletividade do campo `ativo` sozinho. |
| 4 | `idx_evento_tipo` | `evento_trafego (tipo)` | O `GROUP BY tipo` pode ser resolvido lendo só o índice, sem acessar a tabela. |
| 5 | `idx_local_bairro` | `local (bairro)` | Bairro é usado em agrupamentos e filtros nas consultas de eventos e de velocidade por bairro. |
| 6 | `idx_fluxo_disp_velocidade` | `fluxo_trafego (id_dispositivo, velocidade_media, qtd_veiculos)` | É a tabela de maior crescimento (leituras contínuas dos dispositivos). Como o índice contém todas as colunas que as agregações usam, o MySQL responde só com ele (índice de cobertura). |

## 4. Consultas beneficiadas e análise com EXPLAIN

Para cada índice: rode o `EXPLAIN` **antes** de criar o índice, crie o índice, e rode de novo **depois**. Para repetir o teste, use os `DROP INDEX` comentados no fim de `mysql/indices.sql`.

**O que observar no resultado do EXPLAIN:**
- `type`: deve melhorar de `ALL` (varredura completa da tabela) para `ref`, `range` ou `index`.
- `key`: mostra qual índice foi usado (antes aparece `NULL`).
- `rows`: estimativa de linhas lidas, que deve diminuir.
- `Extra`: `Using index` indica índice de cobertura; `Using filesort` indica ordenação extra.

> **Importante:** com poucas linhas nas tabelas, o MySQL pode preferir a varredura completa mesmo com o índice criado, porque ler a tabela inteira sai mais barato. Para o teste mostrar diferença, as tabelas precisam ter volume razoável (alguns milhares de linhas).

### Índice 1: `idx_infracao_data_hora`

```sql
EXPLAIN
SELECT idregistro, iddispositivo, placa_veiculo, data_infracao, horario_infracao
FROM registro_infracao
ORDER BY data_infracao DESC, horario_infracao DESC
LIMIT 10;
```

- Antes: _[colar resultado]_
- Depois: _[colar resultado]_
- Análise: _[o que mudou em type, key e rows]_

### Índice 2: `idx_infracao_placa`

```sql
EXPLAIN
SELECT idregistro, data_infracao, horario_infracao
FROM registro_infracao
WHERE placa_veiculo = 'ABC1D23';
```

- Antes: _[colar resultado]_
- Depois: _[colar resultado]_
- Análise: _[...]_

### Índice 3: `idx_dispositivos_tipo_ativo`

```sql
EXPLAIN
SELECT tipo, COUNT(*) AS total
FROM dispositivo
GROUP BY tipo;
```

- Antes: _[colar resultado]_
- Depois: _[colar resultado]_
- Análise: _[...]_

### Índice 4: `idx_evento_tipo`

```sql
EXPLAIN
SELECT tipo, COUNT(*) AS total
FROM evento_trafego
GROUP BY tipo
ORDER BY total DESC;
```

- Antes: _[colar resultado]_
- Depois: _[colar resultado]_
- Análise: _[...]_

### Índice 5: `idx_local_bairro`

```sql
EXPLAIN
SELECT idlocal, logradouro, bairro
FROM local
WHERE bairro = 'Centro';
```

- Antes: _[colar resultado]_
- Depois: _[colar resultado]_
- Análise: _[...]_

### Índice 6: `idx_fluxo_disp_velocidade`

```sql
EXPLAIN
SELECT id_dispositivo,
       SUM(qtd_veiculos)     AS total_veiculos,
       AVG(velocidade_media) AS velocidade_media
FROM fluxo_trafego
GROUP BY id_dispositivo;
```

- Antes: _[colar resultado]_
- Depois: _[colar resultado]_
- Análise: _[procure `Using index` na coluna Extra. Atenção: o MySQL já mantém um índice simples em `id_dispositivo` por causa da chave estrangeira, então o "antes" não será uma varredura completa; o ganho é o índice de cobertura]_

## 5. Observações

- Índices aceleram leituras, mas deixam inserções, atualizações e exclusões um pouco mais lentas, pois também precisam ser atualizados. Como `fluxo_trafego` recebe muitas escritas, o índice 6 é um equilíbrio consciente: o ganho nas agregações compensa o custo extra.
- Esta análise será referenciada em `docs/grandes_volumes.md`, que trata do crescimento dos dados e do desempenho.
