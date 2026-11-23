
// ============================================================
// INSERÇÃO DE DADOS - MongoDB
// Sistema Inteligente de Controle de Trânsito | Base: monitoramento_transito
//
// Execução: mongosh "SUA_URI" --file mongodb/insercao.js
//
// Este script insere 3 documentos de DEMONSTRAÇÃO em relatorios_acidentes
// (id_evento 90001 a 90003). Eles são alterados e apagados depois por
// atualizacao_exclusao.js, então os dados reais não são afetados.
// ============================================================

db = db.getSiblingDB("monitoramento_transito");

// ------------------------------------------------------------
// 1) Inserção manual de documentos
// Pelo MongoDB Compass: abra a collection relatorios_acidentes ->
// ADD DATA -> Insert document, cole o JSON de um documento e clique em Insert.
// ------------------------------------------------------------

// ------------------------------------------------------------
// Limpeza: remove documentos de demonstração de execuções anteriores (id_evento a partir de 90000).
// Assim o script pode ser rodado várias vezes sem duplicar documentos.
// Os dados reais não são afetados (o maior id_evento real é 5956).
// ------------------------------------------------------------
db.relatorios_acidentes.deleteMany({ id_evento: { $gte: 90000 } });

// ------------------------------------------------------------
// 2) insertOne(): um documento (acidente, com arrays e subdocumentos)
// ------------------------------------------------------------
db.relatorios_acidentes.insertOne({
  id_evento: 90001,
  tipo: "acidente",
  descricao: "Acidente de trânsito com veículos envolvidos, faixa parcialmente interditada.",
  data_hora: ISODate("2026-11-20T14:30:00Z"),
  duracao_minutos: 45,
  local: {
    id_local: 1273,
    logradouro: "Rua Voluntários da Pátria",
    bairro: "Botafogo",
    cidade: "Rio de Janeiro",
    estado: "RJ",
    coordenadas: { type: "Point", coordinates: [-43.274642, -22.948015] }
  },
  dispositivos_envolvidos: [2079],
  gravidade: "leve",
  veiculos_envolvidos: [
    { tipo: "carro", placa: "DMO1A01" },
    { tipo: "moto",  placa: "DMO2B02" }
  ],
  vitimas: { feridos: 1, fatais: 0 },
  condicoes: { clima: "chuva", pista: "molhada" },
  orgaos_acionados: ["SAMU"]
});

// ------------------------------------------------------------
// 3) insertMany(): vários documentos de tipos diferentes na mesma collection
// ------------------------------------------------------------
db.relatorios_acidentes.insertMany([
  {
    id_evento: 90002,
    tipo: "alagamento",
    descricao: "Alagamento na pista devido a chuva forte, trânsito lento.",
    data_hora: ISODate("2026-11-20T15:10:00Z"),
    duracao_minutos: 120,
    local: {
      id_local: 1270,
      logradouro: "Avenida Atlântica",
      bairro: "Copacabana",
      cidade: "Rio de Janeiro",
      estado: "RJ",
      coordenadas: { type: "Point", coordinates: [-43.301624, -22.891774] }
    },
    dispositivos_envolvidos: [],
    nivel_agua_cm: 40,
    faixas_interditadas: 2
  },
  {
    id_evento: 90003,
    tipo: "veiculo_parado",
    descricao: "Veículo quebrado no acostamento, causando lentidão.",
    data_hora: ISODate("2026-11-20T16:05:00Z"),
    duracao_minutos: 30,
    local: {
      id_local: 1296,
      logradouro: "Rua Fonseca",
      bairro: "Bangu",
      cidade: "Rio de Janeiro",
      estado: "RJ",
      coordenadas: { type: "Point", coordinates: [-43.224113, -22.88166] }
    },
    dispositivos_envolvidos: [],
    tipo_defeito: "pane mecânica",
    guincho_acionado: true
  }
]);

print("Documentos de demonstração inseridos: " +
      db.relatorios_acidentes.countDocuments({ id_evento: { $gte: 90000 } }));

// ------------------------------------------------------------
// 4) Importação de dados a partir de arquivos JSON
// Os arquivos exportados do Compass estão em mongodb/dados/ (cada um é um array,
// por isso o --jsonArray). Rode no terminal, NÃO dentro do mongosh.
// Troque USUARIO, SENHA e CLUSTER (ou use mongodb://localhost:27017 para um MongoDB local).
//
// mongoimport --uri "mongodb+srv://USUARIO:SENHA@CLUSTER.mongodb.net/monitoramento_transito" \
//   --collection contagem_trafego --file mongodb/dados/monitoramento_transito.contagem_trafego.json --jsonArray
//
// mongoimport --uri "mongodb+srv://USUARIO:SENHA@CLUSTER.mongodb.net/monitoramento_transito" \
//   --collection metricas_desempenho --file mongodb/dados/monitoramento_transito.metricas_desempenho.json --jsonArray
//
// mongoimport --uri "mongodb+srv://USUARIO:SENHA@CLUSTER.mongodb.net/monitoramento_transito" \
//   --collection dados_geoespaciais --file mongodb/dados/monitoramento_transito.dados_geoespaciais.json --jsonArray
//
// mongoimport --uri "mongodb+srv://USUARIO:SENHA@CLUSTER.mongodb.net/monitoramento_transito" \
//   --collection relatorios_acidentes --file mongodb/dados/monitoramento_transito.relatorios_acidentes.json --jsonArray
//
// mongoimport --uri "mongodb+srv://USUARIO:SENHA@CLUSTER.mongodb.net/monitoramento_transito" \
//   --collection relatorios_transito --file mongodb/dados/monitoramento_transito.relatorios_transito.json --jsonArray
//
// Atenção: se a collection já tiver os mesmos documentos, o mongoimport avisa de _id duplicado.
// Para recriar do zero use a opção --drop (apaga a collection antes de importar).
//
// Pelo Compass: abra a collection -> ADD DATA -> Import JSON or CSV file.
// ------------------------------------------------------------
