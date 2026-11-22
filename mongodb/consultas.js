// ============================================================
// CONSULTAS MONGODB - Sistema Inteligente de Controle de Trânsito
// Base: monitoramento_transito
//
// Execução: mongosh "SUA_URI" --file mongodb/consultas.js
// Antes da consulta 15, crie os índices (mongodb/indices.js): o operador $near exige
// um índice 2dsphere.
//
// No Compass, copie só o filtro (primeiro argumento do find) para a barra de consulta
// e a projeção/ordenação/limite para as opções (Options).
// ============================================================

db = db.getSiblingDB("monitoramento_transito");

function mostrar(titulo, resultado) {
  print("\n=== " + titulo);
  printjson(resultado.toArray ? resultado.toArray() : resultado);
}

// ------------------------------------------------------------
// 1. Quais dispositivos estão inativos?  (filtro, projeção, ordenação)
// ------------------------------------------------------------
mostrar("1. Dispositivos inativos",
  db.dados_geoespaciais
    .find({ tipo: "dispositivo", ativo: false },
          { _id: 0, id_dispositivo: 1, tipo_dispositivo: 1, bairro: 1 })
    .sort({ bairro: 1 })
);

// ------------------------------------------------------------
// 2. Quais as 10 leituras mais lentas (abaixo de 20 km/h) no sentido Norte-Sul?
//    (operador de comparação $lt, ordenação e limite)
// ------------------------------------------------------------
mostrar("2. Leituras mais lentas no sentido Norte-Sul",
  db.contagem_trafego
    .find({ sentido: "Norte-Sul", velocidade_media: { $lt: 20 } },
          { _id: 0, timestamp: 1, id_dispositivo: 1, velocidade_media: 1, qtd_veiculos: 1 })
    .sort({ velocidade_media: 1 })
    .limit(10)
);

// ------------------------------------------------------------
// 3. Quais acidentes foram graves ou tiveram vítimas fatais?
//    (operador lógico $or e campo de documento aninhado)
// ------------------------------------------------------------
mostrar("3. Acidentes graves ou com vítima fatal",
  db.relatorios_acidentes
    .find({ tipo: "acidente",
            $or: [{ gravidade: "grave" }, { "vitimas.fatais": { $gt: 0 } }] },
          { _id: 0, id_evento: 1, gravidade: 1, "vitimas.fatais": 1, "local.bairro": 1, data_hora: 1 })
    .sort({ data_hora: -1 })
);

// ------------------------------------------------------------
// 4. Quais acidentes envolveram ônibus e deixaram feridos?
//    (array de subdocumentos com $elemMatch e operador $gte)
// ------------------------------------------------------------
mostrar("4. Acidentes com ônibus e feridos",
  db.relatorios_acidentes
    .find({ tipo: "acidente",
            veiculos_envolvidos: { $elemMatch: { tipo: "ônibus" } },
            "vitimas.feridos": { $gte: 1 } },
          { _id: 0, id_evento: 1, veiculos_envolvidos: 1, "vitimas.feridos": 1, "local.bairro": 1 })
);

// ------------------------------------------------------------
// 5. Quais ocorrências acionaram SAMU e Corpo de Bombeiros ao mesmo tempo?
//    (array com $all)
// ------------------------------------------------------------
mostrar("5. Ocorrências com SAMU e Corpo de Bombeiros",
  db.relatorios_acidentes
    .find({ orgaos_acionados: { $all: ["SAMU", "Corpo de Bombeiros"] } },
          { _id: 0, id_evento: 1, tipo: 1, orgaos_acionados: 1, "local.bairro": 1 })
);

// ------------------------------------------------------------
// 6. Quais alagamentos tiveram nível de água a partir de 50 cm?
//    (operador $gte, ordenação decrescente)
// ------------------------------------------------------------
mostrar("6. Alagamentos severos",
  db.relatorios_acidentes
    .find({ tipo: "alagamento", nivel_agua_cm: { $gte: 50 } },
          { _id: 0, id_evento: 1, nivel_agua_cm: 1, faixas_interditadas: 1, "local.bairro": 1 })
    .sort({ nivel_agua_cm: -1 })
);

// ------------------------------------------------------------
// 7. Quais veículos parados exigiram guincho por pane mecânica ou pneu furado?
//    (operadores $in e filtro booleano)
// ------------------------------------------------------------
mostrar("7. Veículos parados com guincho",
  db.relatorios_acidentes
    .find({ tipo: "veiculo_parado", guincho_acionado: true,
            tipo_defeito: { $in: ["pane mecânica", "pneu furado"] } },
          { _id: 0, id_evento: 1, tipo_defeito: 1, duracao_minutos: 1, "local.bairro": 1 })
);

// ------------------------------------------------------------
// 8. Quais as 5 ocorrências mais longas (acima de 120 minutos)?
//    (comparação, ordenação decrescente e limite)
// ------------------------------------------------------------
mostrar("8. Ocorrências mais longas",
  db.relatorios_acidentes
    .find({ duracao_minutos: { $gt: 120 } },
          { _id: 0, id_evento: 1, tipo: 1, duracao_minutos: 1, "local.bairro": 1 })
    .sort({ duracao_minutos: -1 })
    .limit(5)
);

// ------------------------------------------------------------
// 9. Quantas ocorrências não têm nenhum dispositivo associado?
//    (tamanho de array com $size e contagem)
// ------------------------------------------------------------
mostrar("9. Ocorrências sem dispositivo associado (total)",
  db.relatorios_acidentes.countDocuments({ dispositivos_envolvidos: { $size: 0 } })
);

// ------------------------------------------------------------
// 10. Em quais ocorrências o dispositivo 2050 esteve envolvido?
//     (busca de um valor dentro de um array)
// ------------------------------------------------------------
mostrar("10. Ocorrências do dispositivo 2050",
  db.relatorios_acidentes
    .find({ dispositivos_envolvidos: 2050 },
          { _id: 0, id_evento: 1, tipo: 1, data_hora: 1, dispositivos_envolvidos: 1 })
);

// ------------------------------------------------------------
// 11. Quais foram os 5 períodos de maior congestionamento (índice a partir de 0,40)?
//     (campo aninhado dentro de kpis)
// ------------------------------------------------------------
mostrar("11. Períodos de maior congestionamento",
  db.metricas_desempenho
    .find({ "kpis.indice_congestionamento": { $gte: 0.40 } },
          { _id: 0, id_dispositivo: 1, tipo_dispositivo: 1, "periodo.inicio": 1,
            "kpis.indice_congestionamento": 1, "kpis.status_via": 1 })
    .sort({ "kpis.indice_congestionamento": -1 })
    .limit(5)
);

// ------------------------------------------------------------
// 12. Em quais meses o bairro Ipanema esteve entre os bairros críticos?
//     (array de subdocumentos, com projeção posicional "$")
// ------------------------------------------------------------
mostrar("12. Meses em que Ipanema foi bairro crítico",
  db.relatorios_transito
    .find({ "bairros_criticos.bairro": "Ipanema" },
          { _id: 0, referencia: 1, "bairros_criticos.$": 1 })
    .sort({ referencia: 1 })
);

// ------------------------------------------------------------
// 13. Quais meses de 2026 tiveram mais de 15 ocorrências?
//     (operador lógico $and combinando texto e número)
// ------------------------------------------------------------
mostrar("13. Meses de 2026 com mais de 15 ocorrências",
  db.relatorios_transito
    .find({ $and: [{ tipo_periodo: "mensal" },
                   { referencia: { $gte: "2026-01" } },
                   { total_ocorrencias: { $gt: 15 } }] },
          { _id: 0, referencia: 1, total_ocorrencias: 1, total_infracoes: 1 })
    .sort({ referencia: 1 })
);

// ------------------------------------------------------------
// 14. Quais dispositivos ficam dentro da "Zona de monitoramento Norte"?
//     (consulta geoespacial com $geoWithin usando o polígono guardado na própria base)
// ------------------------------------------------------------
const zonaNorte = db.dados_geoespaciais.findOne({ tipo: "perimetro", nome: "Zona de monitoramento Norte" });
mostrar("14. Dispositivos dentro da Zona de monitoramento Norte",
  db.dados_geoespaciais
    .find({ tipo: "dispositivo", geometria: { $geoWithin: { $geometry: zonaNorte.geometria } } },
          { _id: 0, id_dispositivo: 1, tipo_dispositivo: 1, bairro: 1 })
    .sort({ bairro: 1 })
);

// ------------------------------------------------------------
// 15. Quais os 5 dispositivos mais próximos do Estádio do Maracanã (até 2 km)?
//     (consulta geoespacial com $near; já retorna ordenado por distância)
//     Exige o índice 2dsphere criado em indices.js
// ------------------------------------------------------------
const maracana = db.dados_geoespaciais.findOne({ tipo: "ponto_interesse", nome: "Estádio do Maracanã" });
mostrar("15. Dispositivos mais próximos do Maracanã",
  db.dados_geoespaciais
    .find({ tipo: "dispositivo",
            geometria: { $near: { $geometry: maracana.geometria, $maxDistance: 2000 } } },
          { _id: 0, id_dispositivo: 1, tipo_dispositivo: 1, bairro: 1 })
    .limit(5)
);
