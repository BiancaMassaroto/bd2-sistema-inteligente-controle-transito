
"""
Painel web da integração MySQL + MongoDB
Sistema Inteligente de Controle de Trânsito

Usa as funções do integracao.py (que precisa estar na mesma pasta).

Instalação (uma vez):
    pip3 install streamlit pandas pymysql pymongo certifi

Configuração (no mesmo terminal em que vai rodar):
    export MYSQL_PASSWORD="sua_senha_mysql"
    export MONGO_URI="sua_uri_do_atlas"

Execução:
    streamlit run painel.py
O painel abre sozinho no navegador (http://localhost:8501).
"""

import os

import pandas as pd
import streamlit as st

import integracao as ig

st.set_page_config(page_title="Controle de Trânsito", page_icon="🚦", layout="wide")


# ---------------------------------------------------------------- conexões
@st.cache_resource
def mongo_db():
    return ig.conectar_mongo()


def novo_mysql():
    return ig.conectar_mysql()


if not os.environ.get("MONGO_URI"):
    st.error("Defina a variável de ambiente MONGO_URI antes de iniciar o painel.")
    st.stop()

try:
    mongo = mongo_db()
    conn = novo_mysql()
except Exception as erro:  # noqa: BLE001
    st.error(f"Não foi possível conectar aos bancos: {erro}")
    st.stop()


# ---------------------------------------------------------------- dados
@st.cache_data(ttl=60)
def carregar_bairros():
    c = novo_mysql()
    try:
        return ig.consolidar_bairros(
            ig.mysql_dispositivos_por_bairro(c),
            ig.mysql_infracoes_por_bairro(c),
            ig.mongo_ocorrencias_por_bairro(mongo_db()),
        )
    finally:
        c.close()


@st.cache_data(ttl=60)
def ids_com_leituras():
    return sorted(mongo_db().contagem_trafego.distinct("id_dispositivo"))


# ---------------------------------------------------------------- cabeçalho
st.title("🚦 Sistema Inteligente de Controle de Trânsito")
st.caption("Painel de integração: MySQL (cadastro e infrações) + MongoDB (leituras e ocorrências)")

if st.sidebar.button("Atualizar dados"):
    st.cache_data.clear()
st.sidebar.markdown("**Ligação entre os bancos**\n\n- dispositivo: `iddispositivos` = `id_dispositivo`\n- bairro: `local.bairro` = `local.bairro`")

bairros = pd.DataFrame(carregar_bairros())

aba1, aba2, aba3 = st.tabs(["Prioridade por bairro", "Pontos cegos", "Ficha do dispositivo"])

# ---------------------------------------------------------------- relatório 1
with aba1:
    st.subheader("Onde concentrar equipes e fiscalização")
    st.write("Ocorrências e acidentes graves (MongoDB) junto com infrações e dispositivos ativos (MySQL).")
    if bairros.empty:
        st.info("Nenhuma ocorrência encontrada.")
    else:
        topo = bairros.sort_values(["graves", "ocorrencias", "infracoes"], ascending=False).head(ig.LIMITE_RANKING)
        c1, c2, c3 = st.columns(3)
        c1.metric("Ocorrências (todas)", int(bairros["ocorrencias"].sum()))
        c2.metric("Graves ou com vítima fatal", int(bairros["graves"].sum()))
        c3.metric("Infrações nesses bairros", int(bairros["infracoes"].sum()))
        st.bar_chart(topo.set_index("bairro")[["ocorrencias", "graves"]])
        st.dataframe(
            topo.rename(columns={"min.perdidos": "minutos afetados"}),
            hide_index=True, use_container_width=True,
        )
        st.caption("Minutos afetados = soma da duração das ocorrências do bairro (impacto, não atraso real dos motoristas).")

# ---------------------------------------------------------------- relatório 2
with aba2:
    st.subheader("Bairros com ocorrências e sem dispositivo ativo")
    st.write("Onde instalar ou reativar equipamentos.")
    if bairros.empty:
        st.info("Nenhuma ocorrência encontrada.")
    else:
        cegos = bairros[bairros["disp.ativos"] == 0].copy()
        cegos["situação"] = cegos["disp.total"].apply(
            lambda t: "sem dispositivo cadastrado" if t == 0 else "dispositivos inativos")
        cegos = cegos.sort_values(["graves", "ocorrencias"], ascending=False)
        c1, c2 = st.columns(2)
        c1.metric("Bairros sem cobertura ativa", len(cegos))
        c2.metric("Bairros com ocorrências", len(bairros))
        st.dataframe(
            cegos[["bairro", "ocorrencias", "graves", "min.perdidos", "disp.total", "situação"]].head(ig.LIMITE_RANKING),
            hide_index=True, use_container_width=True,
        )

# ---------------------------------------------------------------- relatório 3
with aba3:
    st.subheader("Ficha do dispositivo")
    ids = ids_com_leituras()
    if not ids:
        st.info("Nenhum dispositivo com leituras no MongoDB.")
    else:
        padrao = ids.index(ig.DISPOSITIVO_PADRAO) if ig.DISPOSITIVO_PADRAO in ids else 0
        escolhido = st.selectbox("Dispositivo", ids, index=padrao)

        cad = ig.mysql_cadastro_dispositivo(conn, escolhido)
        if not cad:
            st.warning("Dispositivo não encontrado no MySQL.")
        else:
            c1, c2, c3 = st.columns(3)
            c1.metric("Tipo", cad["tipo"])
            c2.metric("Situação", "Ativo" if cad["ativo"] else "INATIVO")
            c3.metric("Bairro", cad["bairro"])
            st.write(f"📍 {cad['logradouro']}, {cad['bairro']} - {cad['cidade']}/{cad['uf']}")

            esq, dir_ = st.columns(2)
            with esq:
                total_inf, recentes = ig.mysql_infracoes_dispositivo(conn, escolhido)
                st.markdown(f"**Infrações registradas (MySQL): {total_inf}**")
                if recentes:
                    st.dataframe(pd.DataFrame(recentes).astype(str), hide_index=True, use_container_width=True)
                else:
                    st.caption("Nenhuma infração registrada.")
            with dir_:
                total_oc, oc = ig.mongo_ocorrencias_dispositivo(mongo, escolhido)
                st.markdown(f"**Ocorrências ligadas ao dispositivo (MongoDB): {total_oc}**")
                if oc:
                    st.dataframe(pd.DataFrame([{
                        "evento": o["id_evento"], "tipo": o["tipo"], "gravidade": o.get("gravidade", "-"),
                        "data": o["data_hora"].strftime("%d/%m/%Y"), "bairro": o["local"]["bairro"],
                        "minutos": o["duracao_minutos"]} for o in oc]), hide_index=True, use_container_width=True)
                else:
                    st.caption("Nenhuma ocorrência ligada a este dispositivo.")

            st.markdown("**Tráfego por hora (MongoDB)** — hora gravada nas leituras, em UTC")
            horas = ig.mongo_lentidao_por_hora(mongo, escolhido)
            if horas:
                df = pd.DataFrame([{
                    "hora": f"{h['_id']:02d}h",
                    "velocidade média (km/h)": round(h["velocidade"], 1),
                    "% de leituras lentas (<20 km/h)": round(100 * h["lentas"] / h["leituras"], 1),
                    "veículos": h["veiculos"]} for h in horas]).set_index("hora")
                g1, g2 = st.columns(2)
                g1.bar_chart(df[["velocidade média (km/h)"]])
                g2.bar_chart(df[["% de leituras lentas (<20 km/h)"]])
                st.dataframe(df, use_container_width=True)
            else:
                st.caption("Sem leituras para este dispositivo.")

conn.close()
