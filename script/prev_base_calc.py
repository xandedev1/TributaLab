#!/usr/bin/env python3
"""Base calc - Lotacoes unificadas (APPA).

Recompoe a base previdenciaria por lotacao x competencia a partir de:
  - S-1010 (dicionario de rubricas / incidencia codIncCP, todos os anos)
  - S-1200 (folha, eventos enviados) com dedup de retificacao

Aplica: patronal 20% + RAT ajustado (RATxFAP fixo) + terceiros (FPAS 515 / 0115).
Gera JSON em storage/private/fiscal_auditor/<empresa>/prev_base_calc.json

Uso:
  python script/prev_base_calc.py --s1010 DIR --eventos DIR [--out FILE] [--mes janeiro.zip]
"""
import os, re, sys, json, zipfile, argparse
from collections import defaultdict
from datetime import datetime, timezone

RATE_PATRONAL = 0.20
RATE_RAT_FAP = 0.023829   # RAT ajustado (RAT 3% x FAP 0,7943) - fixo do estabelecimento 2025
RATE_TERCEIROS = 0.058    # FPAS 515 / codTercs 0115 (empresas) = 5,8%

def val(x, tag):
    m = re.search(r"<%s>(.*?)</%s>" % (tag, tag), x)
    return m.group(1) if m else None

def build_dict(s1010_dir):
    """(codRubr, ideTabRubr) -> {iniValid: (event_id, op, codIncCP, tpRubr)}.

    No mesmo iniValid vale a transmissao mais recente (alteracao/retificacao > inclusao),
    identificada pelo Id do evento (timestamp). Assim uma correcao de incidencia prevalece.
    """
    raw = defaultdict(list)
    for yr in sorted(os.listdir(s1010_dir)):
        yp = os.path.join(s1010_dir, yr)
        if not os.path.isdir(yp):
            continue
        for fn in os.listdir(yp):
            try:
                z = zipfile.ZipFile(os.path.join(yp, fn))
            except Exception:
                continue
            for e in z.namelist():
                if "S-1010" not in e:
                    continue
                d = z.read(e).decode("utf-8", "replace")
                d = re.sub(r"<(ds:)?Signature[\s\S]*?</(ds:)?Signature>", "", d)
                m = re.search(r'Id="([^"]+)"', d)
                event_id = m.group(1) if m else ""
                for mo in re.finditer(r"<(inclusao|alteracao|exclusao)>([\s\S]*?)</\1>", d):
                    op, b = mo.group(1), mo.group(2)
                    cod, tab, ini = val(b, "codRubr"), val(b, "ideTabRubr"), val(b, "iniValid")
                    if cod and tab and ini:
                        raw[(cod, tab)].append((ini, event_id, op, val(b, "codIncCP"), val(b, "tpRubr")))
    dic = {}
    for k, recs in raw.items():
        by_ini = {}
        for ini, eid, op, inc, tp in recs:
            cur = by_ini.get(ini)
            if cur is None or eid > cur[0]:  # transmissao mais recente vence no mesmo iniValid
                by_ini[ini] = (eid, op, inc, tp)
        dic[k] = by_ini
    return dic

def incidencia(dic, cod, tab, per):
    by_ini = dic.get((cod, tab))
    if not by_ini:
        return (None, None, None)
    inis = [i for i in by_ini if i <= per]
    if not inis:
        return (None, None, None)
    eid, op, inc, tp = by_ini[max(inis)]
    if op == "exclusao":
        return (None, None, None)
    return (eid, inc, tp)


MENSAL_RE = re.compile(r"^2025-(0[1-9]|1[0-1])$")  # 2025-01..2025-11 (12/2025 nao transmitido ainda)

def target(ind, per):
    """Retorna (competencia, codIncCP_alvo) ou None. Mensal=11; 13o(indApur=2)=12."""
    if ind == "1" and per and MENSAL_RE.match(per):
        return per, "11"
    if ind == "2" and per == "2025":
        return "2025-13", "12"  # decimo terceiro
    return None

def collect_winners(eventos_dir, mes=None):
    """Dedup GLOBAL entre todos os zips: por (cpf, competencia) mantem o evento de maior Id."""
    winners = {}  # (cpf, comp) -> (idv, zip_path, entry, alvo)
    zips = [mes] if mes else sorted(os.listdir(eventos_dir))
    for fn in zips:
        if not fn.lower().endswith(".zip"):
            continue
        path = os.path.join(eventos_dir, fn)
        print("lendo", fn, "...", flush=True)
        z = zipfile.ZipFile(path)
        for e in z.namelist():
            if "S-1200" not in e:
                continue
            x = z.read(e).decode("utf-8", "replace")
            tg = target(val(x, "indApuracao"), val(x, "perApur"))
            if not tg:
                continue
            comp, alvo = tg
            cpf = val(x, "cpfTrab")
            m = re.search(r'Id="([^"]+)"', x)
            idv = m.group(1) if m else ""
            k = (cpf, comp)
            if k not in winners or idv > winners[k][0]:
                winners[k] = (idv, path, e, alvo)
        z.close()
    return winners

def sum_base(winners, dic, acc):
    """Soma a base (codIncCP alvo) dos eventos vencedores, por (lotacao, competencia, categoria)."""
    by_zip = defaultdict(list)
    for (cpf, comp), (idv, path, entry, alvo) in winners.items():
        by_zip[path].append((entry, comp, alvo))
    for path, items in by_zip.items():
        z = zipfile.ZipFile(path)
        for entry, comp, alvo in items:
            x = z.read(entry).decode("utf-8", "replace")
            x = re.sub(r"<Signature[\s\S]*?</Signature>", "", x)
            cat = val(x, "codCateg")
            per_inc = "2025-12" if comp == "2025-13" else comp  # vigencia da rubrica p/ 13o = fim do ano
            # itera ideEstabLot (cobre infoPerApur E infoPerAnt = ajustes retroativos/dissidio)
            for blk in re.finditer(r"<ideEstabLot>([\s\S]*?)</ideEstabLot>", x):
                b = blk.group(1)
                lot = val(b, "codLotacao")
                for it in re.finditer(r"<itensRemun>([\s\S]*?)</itensRemun>", b):
                    ib = it.group(1)
                    cod, tab, vr = val(ib, "codRubr"), val(ib, "ideTabRubr"), val(ib, "vrRubr")
                    if cod and tab and vr and incidencia(dic, cod, tab, per_inc)[1] == alvo:
                        acc[(lot, comp, cat)] += float(vr)
        z.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--s1010", required=True)
    ap.add_argument("--eventos", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--mes", default=None, help="processa so um zip (ex.: janeiro.zip)")
    args = ap.parse_args()

    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    print("montando dicionario S-1010...", flush=True)
    dic = build_dict(args.s1010)
    print("  rubricas:", len(dic), flush=True)

    acc = defaultdict(float)  # (lot, comp, cat) -> base
    winners = collect_winners(args.eventos, args.mes)
    print("  eventos vencedores (dedup global):", len(winners), flush=True)
    sum_base(winners, dic, acc)

    rows = []
    for (lot, per, cat), base in sorted(acc.items()):
        patronal = round(base * RATE_PATRONAL, 2)
        rat_fap = round(base * RATE_RAT_FAP, 2)
        terceiros = round(base * RATE_TERCEIROS, 2)
        total = round(patronal + rat_fap + terceiros, 2)
        rows.append({
            "lotacao": lot, "competencia": per, "categoria": cat,
            "base_inss": round(base, 2), "patronal": patronal,
            "rat_fap": rat_fap, "terceiros": terceiros, "total_prev": total,
        })

    def s(k):
        return round(sum(r[k] for r in rows), 2)
    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "rates": {"patronal": RATE_PATRONAL, "rat_fap": RATE_RAT_FAP, "terceiros": RATE_TERCEIROS},
        "totais": {"base_inss": s("base_inss"), "patronal": s("patronal"),
                   "rat_fap": s("rat_fap"), "terceiros": s("terceiros"), "total_prev": s("total_prev")},
        "rows": rows,
    }
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False)
    print("OK ->", args.out, "|", len(rows), "linhas | total_prev", payload["totais"]["total_prev"], flush=True)

if __name__ == "__main__":
    main()
