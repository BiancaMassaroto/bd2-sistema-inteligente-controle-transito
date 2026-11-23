# Sistema Inteligente de Controle de Trânsito

Projeto de Banco de Dados — Engenharia da Computação, UNIVAP.

Solução de dados para um sistema inteligente de controle de trânsito, que combina um banco **relacional (MySQL)** e um banco **não relacional (MongoDB)** na mesma arquitetura.

## Integrantes

- [Nome dos integrantes]

**Disciplina:** Banco de Dados
**Professor(a):** [nome]

## Sobre o projeto

O sistema gerencia dispositivos de monitoramento de trânsito (câmeras, sensores, semáforos) instalados em locais de diferentes cidades. Ele registra o fluxo de veículos, infrações, eventos de trânsito, ciclos de semáforo e logs de operação dos dispositivos feitos por funcionários.

Como o monitoramento gera grandes volumes de informação continuamente, a solução usa dois bancos com papéis diferentes.

## Arquitetura:

### MySQL (dados estruturados e relacionados)

Guarda os dados que exigem integridade referencial:

- localização: estados, cidades e locais;
- dispositivos e sua instalação;
- funcionários e logs de dispositivos;
- infrações, eventos de trânsito, fluxo de tráfego e ciclos de semáforo.

### MongoDB (dados em documentos)

[A PREENCHER PELO GRUPO: quais dados estão no MongoDB, quais collections existem e por que documentos são mais adequados para eles (por exemplo, eventos e leituras com estrutura variável ou aninhada, em grande volume).]

## Tecnologias

- MySQL (com MySQL Workbench)
- MongoDB (com MongoDB Compass ou mongosh)
- Git e GitHub

## Modelo relacional

Principais tabelas do MySQL:

| Tabela | Descrição |
|---|---|
| `estado`, `cidade`, `local` | Localização dos dispositivos |
| `dispositivo` | Dispositivos de monitoramento instalados em cada local |
| `fluxo_trafego` | Leituras de quantidade e velocidade média de veículos |
| `registro_infracao` | Infrações detectadas pelos dispositivos |
| `evento_trafego` | Eventos de trânsito ocorridos em um local |
| `dispositivos_incidentes` | Relação entre dispositivos e eventos |
| `ciclo_semaforo` | Tempos de verde, amarelo e vermelho dos semáforos |
| `funcionario` | Funcionários responsáveis pelos dispositivos |
| `logs_dispositivos` | Registros de operação dos dispositivos |

O modelo completo está em `docs/mer.png` e `docs/modelo_relacional.png`, e a descrição de cada campo está em `docs/dicionario_dados.md`.

## Como executar

### Pré-requisitos

- MySQL 8 ou superior
- MongoDB 6 ou superior, com as ferramentas de linha de comando (`mongoimport`, `mongosh`)

### MySQL

Execute os scripts **nesta ordem** (cada um depende do anterior):

```bash
mysql -u root -p < mysql/ddl.sql
mysql -u root -p < mysql/dml.sql
mysql -u root -p < mysql/views.sql
mysql -u root -p < mysql/procedures.sql
mysql -u root -p < mysql/triggers.sql
mysql -u root -p < mysql/indices.sql
mysql -u root -p < mysql/usuarios_permissoes.sql
```

As consultas ficam em `mysql/consultas.sql` e podem ser executadas à vontade depois dos passos acima.

Também é possível abrir cada arquivo `.sql` no MySQL Workbench e executar.

### MongoDB

Importe os arquivos JSON para a base (substitua pelos nomes reais):

```bash
mongoimport --db NOME_DA_BASE --collection NOME_DA_COLLECTION \
  --file mongodb/dados/ARQUIVO.json --jsonArray
```

Depois, execute as consultas e as agregações com o `mongosh`:

```bash
mongosh NOME_DA_BASE mongodb/consultas.js
mongosh NOME_DA_BASE mongodb/aggregations.js
```
