// ============================================================
// ÍNDICES MONGODB - Sistema Inteligente de Controle de Trânsito
// Base: monitoramento_transito
//
// Execução: mongosh "SUA_URI" --file mongodb/indices.js
// Rode ANTES de consultas.js (a consulta 15 exige o índice 2dsphere).
// A análise e as justificativas também estão em docs/mongodb.md.
// ============================================================

db = db.getSiblingDB("monitoramento_transito");

// ------------------------------------------------------------
// ÍNDICE 1: dados_geoespaciais.geometria (2dsphere)
// Justificativa: permite consultas por localização ($near, $geoWithin) sem varrer
// toda a collection. O operador $near só funciona com esse tipo de índice.
// Consulta beneficiada: dispositivos próximos de um ponto ou dentro de um perímetro.
// ------------------------------------------------------------
db.dados_geoespaciais.createIndex({ geometria: "2dsphere" });

// ------------------------------------------------------------
// ÍNDICE 2: contagem_trafego (id_dispositivo, timestamp)
// Justificativa: contagem_trafego é a collection que mais cresce (uma leitura por minuto
// por dispositivo). As consultas buscam as leituras de um dispositivo em uma janela de tempo,
// e esse índice composto atende o filtro e a ordenação ao mesmo tempo.
// Consulta beneficiada: leituras de um dispositivo em uma hora.
// ------------------------------------------------------------
db.contagem_trafego.createIndex({ id_dispositivo: 1, timestamp: -1 }, { name: "idx_dispositivo_tempo" });

// ------------------------------------------------------------
// ÍNDICE 3: relatorios_acidentes (tipo, data_hora)
// Justificativa: as consultas e agregações filtram por tipo de ocorrência e período,
// e geralmente ordenam pelas mais recentes.
// Consulta beneficiada: alagamentos desde uma data, ordenados do mais recente.
// ------------------------------------------------------------
db.relatorios_acidentes.createIndex({ tipo: 1, data_hora: -1 }, { name: "idx_tipo_data" });

print("Índices criados:");
printjson(db.dados_geoespaciais.getIndexes().map(i => i.name));
printjson(db.contagem_trafego.getIndexes().map(i => i.name));
printjson(db.relatorios_acidentes.getIndexes().map(i => i.name));

// ------------------------------------------------------------
// COMPARAÇÃO ANTES x DEPOIS (explain)
// Compara o plano SEM índice (hint $natural força a leitura da collection inteira)
// com o plano COM índice. Procure no resultado:
//   estágio: COLLSCAN (sem índice) ou IXSCAN (com índice)
//   docsExaminados: quantos documentos foram lidos para devolver o resultado
// ------------------------------------------------------------
function estagios(p) {
  let s = [p.stage];
  if (p.inputStage) s = s.concat(estagios(p.inputStage));
  if (p.inputStages) p.inputStages.forEach(i => { s = s.concat(estagios(i)); });
  return s;
}

function resumo(rotulo, cursor, hint) {
  const c = hint ? cursor.hint(hint) : cursor;
  const e = c.explain("executionStats");
  const plano = e.queryPlanner.winningPlan.queryPlan || e.queryPlanner.winningPlan;
  print(rotulo + " | estágios: " + estagios(plano).join(" > ") +
        " | docsExaminados: " + e.executionStats.totalDocsExamined +
        " | retornados: " + e.executionStats.nReturned +
        " | ms: " + e.executionStats.executionTimeMillis);
}

print("\n--- Índice 1: dispositivos dentro de 2 km do Maracanã ($geoWithin)");
const raio = { geometria: { $geoWithin: { $centerSphere: [[-43.2302, -22.9121], 2000 / 6378100] } } };
resumo("SEM índice", db.dados_geoespaciais.find(raio), { $natural: 1 });
resumo("COM índice", db.dados_geoespaciais.find(raio));

print("\n--- Índice 2: leituras do dispositivo 110 entre 17h e 18h");
const janela = { id_dispositivo: 110,
                 timestamp: { $gte: ISODate("2026-11-18T17:00:00Z"), $lt: ISODate("2026-11-18T18:00:00Z") } };
resumo("SEM índice", db.contagem_trafego.find(janela).sort({ timestamp: -1 }), { $natural: 1 });
resumo("COM índice", db.contagem_trafego.find(janela).sort({ timestamp: -1 }));

print("\n--- Índice 3: alagamentos desde junho de 2026, mais recentes primeiro");
const alag = { tipo: "alagamento", data_hora: { $gte: ISODate("2026-06-01T00:00:00Z") } };
resumo("SEM índice", db.relatorios_acidentes.find(alag).sort({ data_hora: -1 }), { $natural: 1 });
resumo("COM índice", db.relatorios_acidentes.find(alag).sort({ data_hora: -1 }));
