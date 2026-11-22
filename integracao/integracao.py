
"""
Integração MySQL + MongoDB
Sistema Inteligente de Controle de Trânsito

O MySQL guarda o cadastro e o histórico formal (dispositivo, local, infrações).
O MongoDB guarda as leituras e os relatórios de campo (contagem_trafego,
relatorios_acidentes). Os dois se ligam por:
    - dispositivo: MySQL dispositivo.iddispositivos  =  MongoDB id_dispositivo
    - bairro:      MySQL local.bairro                =  MongoDB local.bairro

Relatórios (cada um responde a uma decisão real da central de trânsito):
    1. Prioridade de intervenção por bairro
       Onde concentrar equipes e fiscalização: ocorrências e acidentes graves (MongoDB)
       junto com infrações e dispositivos ativos (MySQL).
    2. Pontos cegos de monitoramento
       Bairros com ocorrências (MongoDB) onde não há nenhum dispositivo ativo (MySQL):
       onde instalar ou reativar equipamentos.
    3. Ficha de um dispositivo
       Visão completa de um equipamento: cadastro e infrações recentes (MySQL),
       lentidão por horário e ocorrências ligadas a ele (MongoDB).

Instalação (uma vez):
    pip3 install pymysql pymongo certifi

Configuração (variáveis de ambiente, nunca escreva senha no código):
    export MYSQL_PASSWORD="sua_senha_mysql"
    export MONGO_URI="sua_uri_do_atlas"
    Opcionais (padrão entre parênteses): MYSQL_HOST (localhost), MYSQL_PORT (3306),
    MYSQL_USER (root), MYSQL_DATABASE (sistema_transito), MONGO_DB (monitoramento_transito)

Execução:
    python integracao.py          # relatórios 1 e 2 e a ficha do dispositivo 110
    python integracao.py 43       # relatórios 1 e 2 e a ficha do dispositivo 43
"""

import os
import sys
import unicodedata

import pymysql
from pymongo import MongoClient

LIMITE_RANKING = 10          # quantos bairros mostrar nos relatórios 1 e 2
DISPOSITIVO_PADRAO = 110     # dispositivo da ficha quando nenhum id é informado


# ---------------------------------------------------------------- conexões
def conectar_mysql():
    return pymysql.connect(
        host=os.environ.get("MYSQL_HOST", "localhost"),
        port=int(os.environ.get("MYSQL_PORT", "3306")),
        user=os.environ.get("MYSQL_USER", "root"),
        password=os.environ.get("MYSQL_PASSWORD", ""),
        database=os.environ.get("MYSQL_DATABASE", "sistema_transito"),
        cursorclass=pymysql.cursors.DictCursor,
    )


def conectar_mongo():
    uri = os.environ.get("MONGO_URI")
    if not uri:
        sys.exit("Defina a variável de ambiente MONGO_URI antes de executar.")
    opcoes = {"serverSelectionTimeoutMS": 8000}
    try:
        # Usa os certificados do pacote certifi (resolve CERTIFICATE_VERIFY_FAILED no Mac)
        import certifi
        opcoes["tlsCAFile"] = certifi.where()
    except ImportError:
        pass
    cliente = MongoClient(uri, **opcoes)
    return cliente[os.environ.get("MONGO_DB", "monitoramento_transito")]


# ---------------------------------------------------------------- apoio
def titulo(texto):
    print("\n" + "=" * 78)
    print(texto)
    print("=" * 78)


def tabela(linhas, colunas):
    """Imprime uma lista de dicionários como tabela de texto."""
    if not linhas:
        print("(nenhum resultado)")
        return
    larguras = {c: max(len(c), *(len(str(l.get(c, ""))) for l in linhas)) for c in colunas}
    print("  ".join(c.ljust(larguras[c]) for c in colunas))
    print("  ".join("-" * larguras[c] for c in colunas))
    for l in linhas:
        print("  ".join(str(l.get(c, "")).ljust(larguras[c]) for c in colunas))


def chave_bairro(nome):
    """Normaliza o nome do bairro (sem acento, minúsculo) para comparar os dois bancos."""
    sem_acento = unicodedata.normalize("NFKD", nome or "").encode("ascii", "ignore").decode()
    return " ".join(sem_acento.lower().split())


# ---------------------------------------------------------------- MySQL
def mysql_dispositivos_por_bairro(conn):
    sql = """
        SELECT l.bairro, COUNT(*) AS total, SUM(d.ativo = 1) AS ativos
        FROM dispositivo d
        INNER JOIN local l ON l.idlocal = d.idlocal
        GROUP BY l.bairro
    """
    with conn.cursor() as cur:
        cur.execute(sql)
        return {chave_bairro(r["bairro"]): r for r in cur.fetchall()}


def mysql_infracoes_por_bairro(conn):
    sql = """
        SELECT l.bairro, COUNT(*) AS infracoes
        FROM registro_infracao r
        INNER JOIN dispositivo d ON d.iddispositivos = r.iddispositivo
        INNER JOIN local l       ON l.idlocal = d.idlocal
        GROUP BY l.bairro
    """
    with conn.cursor() as cur:
        cur.execute(sql)
        return {chave_bairro(r["bairro"]): r["infracoes"] for r in cur.fetchall()}


def mysql_cadastro_dispositivo(conn, id_dispositivo):
    sql = """
        SELECT d.iddispositivos AS id_dispositivo, d.tipo, d.ativo,
               l.logradouro, l.bairro, c.nome AS cidade, e.sigla AS uf
        FROM dispositivo d
        INNER JOIN local  l ON l.idlocal  = d.idlocal
        INNER JOIN cidade c ON c.idcidade = l.idcidade
        INNER JOIN estado e ON e.idestado = c.idestado
        WHERE d.iddispositivos = %s
    """
    with conn.cursor() as cur:
        cur.execute(sql, (id_dispositivo,))
        return cur.fetchone()


def mysql_infracoes_dispositivo(conn, id_dispositivo, limite=5):
    sql = """
        SELECT data_infracao, horario_infracao, placa_veiculo
        FROM registro_infracao
        WHERE iddispositivo = %s
        ORDER BY data_infracao DESC, horario_infracao DESC
        LIMIT %s
    """
    with conn.cursor() as cur:
        cur.execute(sql, (id_dispositivo, limite))
        total_sql = "SELECT COUNT(*) AS n FROM registro_infracao WHERE iddispositivo = %s"
        recentes = cur.fetchall()
        cur.execute(total_sql, (id_dispositivo,))
        return cur.fetchone()["n"], recentes


# ---------------------------------------------------------------- MongoDB
def mongo_ocorrencias_por_bairro(mongo):
    """Por bairro: total de ocorrências, graves (ou com vítima fatal) e minutos de interferência."""
    pipeline = [
        {"$group": {
            "_id": "$local.bairro",
            "ocorrencias": {"$sum": 1},
            "graves": {"$sum": {"$cond": [{"$or": [
                {"$eq": ["$gravidade", "grave"]},
                {"$gt": [{"$ifNull": ["$vitimas.fatais", 0]}, 0]},
            ]}, 1, 0]}},
            "minutos": {"$sum": "$duracao_minutos"},
        }},
    ]
    return {chave_bairro(d["_id"]): {"bairro": d["_id"], **d} for d in mongo.relatorios_acidentes.aggregate(pipeline)}


def mongo_lentidao_por_hora(mongo, id_dispositivo):
    pipeline = [
        {"$match": {"id_dispositivo": id_dispositivo}},
        {"$group": {
            "_id": {"$hour": "$timestamp"},
            "leituras": {"$sum": 1},
            "veiculos": {"$sum": "$qtd_veiculos"},
            "velocidade": {"$avg": "$velocidade_media"},
            "lentas": {"$sum": {"$cond": [{"$lt": ["$velocidade_media", 20]}, 1, 0]}},
        }},
        {"$sort": {"_id": 1}},
    ]
    return list(mongo.contagem_trafego.aggregate(pipeline))


def mongo_ocorrencias_dispositivo(mongo, id_dispositivo, limite=5):
    filtro = {"dispositivos_envolvidos": id_dispositivo}
    total = mongo.relatorios_acidentes.count_documents(filtro)
    recentes = list(mongo.relatorios_acidentes.find(
        filtro,
        {"_id": 0, "id_evento": 1, "tipo": 1, "gravidade": 1, "data_hora": 1,
         "duracao_minutos": 1, "local.bairro": 1},
    ).sort("data_hora", -1).limit(limite))
    return total, recentes


# ---------------------------------------------------------------- relatórios
def consolidar_bairros(disp, infr, ocorr):
    """Junta, por bairro, o que veio do MySQL (disp, infr) e do MongoDB (ocorr)."""
    linhas = []
    for chave, o in ocorr.items():
        d = disp.get(chave)
        linhas.append({
            "bairro": o["bairro"],
            "ocorrencias": o["ocorrencias"],
            "graves": o["graves"],
            "min.perdidos": o["minutos"],
            "infracoes": infr.get(chave, 0),
            "disp.total": int(d["total"]) if d else 0,
            "disp.ativos": int(d["ativos"] or 0) if d else 0,
        })
    return linhas


def relatorio_1(linhas):
    titulo("1. Prioridade de intervenção por bairro  (MongoDB: ocorrências | MySQL: infrações e dispositivos)")
    print("Critério: mais ocorrências graves, depois mais ocorrências, depois mais infrações.\n")
    ordenado = sorted(linhas, key=lambda x: (x["graves"], x["ocorrencias"], x["infracoes"]), reverse=True)
    tabela(ordenado[:LIMITE_RANKING],
           ["bairro", "ocorrencias", "graves", "min.perdidos", "infracoes", "disp.ativos"])


def relatorio_2(linhas):
    titulo("2. Pontos cegos de monitoramento  (bairros com ocorrências e sem dispositivo ativo)")
    print("Onde instalar ou reativar equipamentos.\n")
    cegos = [l for l in linhas if l["disp.ativos"] == 0]
    cegos.sort(key=lambda x: (x["graves"], x["ocorrencias"]), reverse=True)
    for l in cegos:
        l["situacao"] = "sem dispositivo cadastrado" if l["disp.total"] == 0 else "dispositivos inativos"
    tabela(cegos[:LIMITE_RANKING],
           ["bairro", "ocorrencias", "graves", "min.perdidos", "disp.total", "situacao"])
    print(f"\nTotal de bairros sem cobertura ativa: {len(cegos)} de {len(linhas)} com ocorrências.")


def relatorio_3(conn, mongo, id_dispositivo):
    titulo(f"3. Ficha do dispositivo {id_dispositivo}")
    cad = mysql_cadastro_dispositivo(conn, id_dispositivo)
    if not cad:
        print("Dispositivo não encontrado no MySQL.")
        return
    print("[MySQL] Cadastro")
    print(f"  Tipo: {cad['tipo']} | Situação: {'ativo' if cad['ativo'] else 'INATIVO'}")
    print(f"  Local: {cad['logradouro']}, {cad['bairro']} - {cad['cidade']}/{cad['uf']}")

    total_inf, recentes = mysql_infracoes_dispositivo(conn, id_dispositivo)
    print(f"\n[MySQL] Infrações registradas: {total_inf} (mais recentes abaixo)")
    tabela([{"data": str(r["data_infracao"]), "horario": str(r["horario_infracao"]),
             "placa": r["placa_veiculo"]} for r in recentes], ["data", "horario", "placa"])

    horas = mongo_lentidao_por_hora(mongo, id_dispositivo)
    print("\n[MongoDB] Tráfego por hora (hora gravada nas leituras, em UTC)")
    tabela([{"hora": f"{h['_id']:02d}h", "leituras": h["leituras"], "veiculos": h["veiculos"],
             "vel.media": round(h["velocidade"], 1),
             "%lento(<20km/h)": round(100 * h["lentas"] / h["leituras"], 1)} for h in horas],
           ["hora", "leituras", "veiculos", "vel.media", "%lento(<20km/h)"])

    total_oc, oc = mongo_ocorrencias_dispositivo(mongo, id_dispositivo)
    print(f"\n[MongoDB] Ocorrências ligadas ao dispositivo: {total_oc}")
    tabela([{"evento": o["id_evento"], "tipo": o["tipo"], "gravidade": o.get("gravidade", "-"),
             "data": o["data_hora"].strftime("%d/%m/%Y"), "bairro": o["local"]["bairro"],
             "min": o["duracao_minutos"]} for o in oc],
           ["evento", "tipo", "gravidade", "data", "bairro", "min"])


def main():
    id_dispositivo = int(sys.argv[1]) if len(sys.argv) > 1 else DISPOSITIVO_PADRAO
    conn = conectar_mysql()
    mongo = conectar_mongo()
    try:
        linhas = consolidar_bairros(
            mysql_dispositivos_por_bairro(conn),
            mysql_infracoes_por_bairro(conn),
            mongo_ocorrencias_por_bairro(mongo),
        )
        relatorio_1(linhas)
        relatorio_2(linhas)
        relatorio_3(conn, mongo, id_dispositivo)
    finally:
        conn.close()


if __name__ == "__main__":
    main()