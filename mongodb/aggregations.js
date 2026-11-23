
// ============================================================
// AGGREGATION PIPELINES - Sistema Inteligente de Controle de Trânsito
// Base: monitoramento_transito
//
// Execução: mongosh "SUA_URI" --file mongodb/aggregations.js
// No Compass: abra a collection -> aba Aggregations -> cole os estágios (o array).
// ============================================================

db = db.getSiblingDB("monitoramento_transito");

function mostrar(titulo, resultado) {
  print("\n=== " + titulo);
  printjson(resultado.toArray ? resultado.toArray() : resultado);
}

// ------------------------------------------------------------
// 1. Qual o impacto de cada tipo de ocorrência em 2026: quantidade, duração média e maior duração?
//    Estágios: $match, $group, $project, $sort
// ------------------------------------------------------------
mostrar("1. Impacto por tipo de ocorrência (2026)",
  db.relatorios_acidentes.aggregate([
    { $match: { data_hora: { $gte: ISODate("2026-01-01T00:00:00Z") } } },
    { $group: {
        _id: "$tipo",
        total_ocorrencias: { $sum: 1 },
        duracao_media_min: { $avg: "$duracao_minutos" },
        maior_duracao_min: { $max: "$duracao_minutos" }
    } },
    { $project: {
        _id: 0,
        tipo: "$_id",
        total_ocorrencias: 1,
        duracao_media_min: { $round: ["$duracao_media_min", 1] },
        maior_duracao_min: 1
    } },
    { $sort: { duracao_media_min: -1 } }
  ])
);

// ------------------------------------------------------------
// 2. Quais tipos de veículo mais aparecem nos acidentes?
//    Estágios: $match, $unwind (desmonta o array de veículos), $group, $project, $sort
// ------------------------------------------------------------
mostrar("2. Tipos de veículo mais envolvidos em acidentes",
  db.relatorios_acidentes.aggregate([
    { $match: { tipo: "acidente" } },
    { $unwind: "$veiculos_envolvidos" },
    { $group: {
        _id: "$veiculos_envolvidos.tipo",
        total_veiculos: { $sum: 1 },
        acidentes: { $addToSet: "$id_evento" }
    } },
    { $project: { _id: 0, tipo_veiculo: "$_id", total_veiculos: 1, total_acidentes: { $size: "$acidentes" } } },
    { $sort: { total_veiculos: -1 } }
  ])
);

// ------------------------------------------------------------
// 3. Em qual dispositivo e sentido há mais lentidão?
//    Percentual de leituras com velocidade abaixo de 20 km/h, por dispositivo e sentido.
//    Estágios: $group (com $cond), $project, $sort
// ------------------------------------------------------------
mostrar("3. Lentidão por dispositivo e sentido",
  db.contagem_trafego.aggregate([
    { $group: {
        _id: { dispositivo: "$id_dispositivo", sentido: "$sentido" },
        leituras: { $sum: 1 },
        velocidade_media: { $avg: "$velocidade_media" },
        leituras_lentas: { $sum: { $cond: [{ $lt: ["$velocidade_media", 20] }, 1, 0] } }
    } },
    { $project: {
        _id: 0,
        id_dispositivo: "$_id.dispositivo",
        sentido: "$_id.sentido",
        leituras: 1,
        velocidade_media: { $round: ["$velocidade_media", 1] },
        percentual_lento: { $round: [{ $multiply: [{ $divide: ["$leituras_lentas", "$leituras"] }, 100] }, 1] }
    } },
    { $sort: { percentual_lento: -1 } }
  ])
);

// ------------------------------------------------------------
// 4. Onde estão os dispositivos mais congestionados?
//    Junta as métricas de desempenho com a localização do dispositivo.
//    Estágios: $group, $lookup (une duas collections), $unwind, $project, $sort
// ------------------------------------------------------------
mostrar("4. Congestionamento médio por dispositivo, com bairro",
  db.metricas_desempenho.aggregate([
    { $group: {
        _id: "$id_dispositivo",
        tipo: { $first: "$tipo_dispositivo" },
        congestionamento_medio: { $avg: "$kpis.indice_congestionamento" },
        velocidade_media: { $avg: "$kpis.velocidade_media_kmh" },
        total_veiculos: { $sum: "$kpis.total_veiculos" }
    } },
    { $lookup: {
        from: "dados_geoespaciais",
        localField: "_id",
        foreignField: "id_dispositivo",
        as: "local"
    } },
    { $unwind: "$local" },
    { $project: {
        _id: 0,
        id_dispositivo: "$_id",
        tipo: 1,
        bairro: "$local.bairro",
        logradouro: "$local.logradouro",
        congestionamento_medio: { $round: ["$congestionamento_medio", 2] },
        velocidade_media: { $round: ["$velocidade_media", 1] },
        total_veiculos: 1
    } },
    { $sort: { congestionamento_medio: -1 } }
  ])
);
