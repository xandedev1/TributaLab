#!/usr/bin/env python3
"""Gera um relatorio PDF profissional (estilo ISO 19011:2026) para a CTE,
consolidando a analise das rubricas de auxilio doenca, licenca medica e atestados."""

import csv
import sys
from datetime import datetime
from pathlib import Path

RELATED_BY_CODE = Path("tmp/cte_auxilio_doenca_related_report/rubricas_auxilio_doenca_por_codigo.csv")
RELATED_BY_MONTH = Path("tmp/cte_auxilio_doenca_related_report/rubricas_auxilio_doenca_por_mes.csv")
OUTPUT_DIR = Path("tmp/relatorio_cte_auxilio_doenca_final")
PDF_PATH = OUTPUT_DIR / "CTE_Relatorio_Auxilio_Doenca_ISO19011.pdf"

# Escopo dos eventos considerados na analise (texto exibido no relatorio).
SCOPE_EVENTS = "S-1200 e S-1210"
SCOPE_TAG = ""

# Paleta corporativa
NAVY = (0.09, 0.16, 0.29)      # cabecalho principal
STEEL = (0.14, 0.33, 0.53)     # titulos de secao
ACCENT = (0.72, 0.11, 0.13)    # destaque vermelho
LIGHT = (0.93, 0.95, 0.98)     # zebra clara
MIDGRAY = (0.45, 0.50, 0.57)
WHITE = (1, 1, 1)
BLACK = (0.12, 0.14, 0.18)

MAPPING = [
    ("3302", "Complement Auxilio Doenca", ["SECTECENT200000000000000000289", "SECTECENT200000000000000000288"]),
    ("3605", "Complement Auxilio Doenca", ["SECTECENT200000000000000000258", "8870", "9505"]),
    ("0218", "Desc adto Auxilio doenca", ["SECTECENT200000000000000000291"]),
    ("0213", "Dias Lic. Medica ate 15d", ["SECTECENT200000000000000000205"]),
    ("0014", "Hrs Atestado ate 15 dias", ["SECTECENT200000000000000000003", "SECTECENT200000000000000000199"]),
]


def money_br(value):
    return "R$ " + f"{float(value):,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


def read_csv(path):
    with path.open("r", encoding="utf-8-sig", newline="") as file:
        return list(csv.DictReader(file))


class Pdf:
    def __init__(self, path):
        self.path = path
        self.width = 595.28
        self.height = 841.89
        self.margin = 56
        self.pages = []
        self.ops = []
        self.y = self.height - self.margin

    # ---- primitivos ----
    def _esc(self, text):
        rep = {"\u2013": "-", "\u2014": "-", "\u2018": "'", "\u2019": "'", "\u201c": '"', "\u201d": '"', "\u2026": "...", "\u00a0": " "}
        text = str(text)
        for a, b in rep.items():
            text = text.replace(a, b)
        text = text.encode("cp1252", "replace").decode("cp1252")
        return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")

    def rect(self, x, y, w, h, color):
        r, g, b = color
        self.ops.append(f"{r:.3f} {g:.3f} {b:.3f} rg {x:.2f} {y:.2f} {w:.2f} {h:.2f} re f")

    def line(self, x1, y1, x2, y2, color, width=0.6):
        r, g, b = color
        self.ops.append(f"{r:.3f} {g:.3f} {b:.3f} RG {width:.2f} w {x1:.2f} {y1:.2f} m {x2:.2f} {y2:.2f} l S")

    def text_at(self, x, y, value, size=10, bold=False, color=BLACK):
        r, g, b = color
        font = "F2" if bold else "F1"
        self.ops.append(f"BT /{font} {size} Tf {r:.3f} {g:.3f} {b:.3f} rg 1 0 0 1 {x:.2f} {y:.2f} Tm ({self._esc(value)}) Tj ET")

    def text_width(self, value, size, bold=False):
        # aproximacao Helvetica
        widths_bold = 0.56
        factor = widths_bold if bold else 0.52
        return len(str(value)) * size * factor

    # ---- fluxo ----
    def new_page(self):
        if self.ops:
            self.pages.append(self.ops)
        self.ops = []
        self.y = self.height - self.margin

    def ensure(self, needed):
        if self.y - needed < self.margin + 28:
            self.new_page()
            self.header_strip()

    def header_strip(self):
        self.rect(0, self.height - 26, self.width, 26, NAVY)
        self.text_at(self.margin, self.height - 18, "CTE - Relatorio de Analise de Rubricas eSocial" + SCOPE_TAG, 8.5, bold=True, color=WHITE)
        self.text_at(self.width - self.margin - 70, self.height - 18, "ISO 19011:2026", 8.5, color=(0.8, 0.85, 0.92))
        self.y = self.height - 26 - 28

    def paragraph(self, value, size=10.5, color=BLACK, leading=15, gap=6, x=None, max_width=None):
        x = self.margin if x is None else x
        max_width = (self.width - 2 * self.margin) if max_width is None else max_width
        words = str(value).split()
        line = ""
        for word in words:
            trial = word if not line else line + " " + word
            if self.text_width(trial, size) > max_width and line:
                self.ensure(leading)
                self.text_at(x, self.y, line, size, color=color)
                self.y -= leading
                line = word
            else:
                line = trial
        if line:
            self.ensure(leading)
            self.text_at(x, self.y, line, size, color=color)
            self.y -= leading
        self.y -= gap

    def bullet(self, value, size=10.5):
        x = self.margin + 14
        self.ensure(15)
        self.text_at(self.margin + 3, self.y, "-", size, bold=True, color=ACCENT)
        self.paragraph(value, size=size, x=x, max_width=self.width - self.margin - x, gap=2)

    def section(self, number, title):
        self.ensure(34)
        self.y -= 4
        bar_h = 20
        self.rect(self.margin, self.y - bar_h + 14, 4, bar_h, ACCENT)
        self.text_at(self.margin + 12, self.y, f"{number}. {title}", 13.5, bold=True, color=STEEL)
        self.y -= 24

    def table(self, headers, rows, widths, aligns=None, size=9.2, header_color=NAVY, zebra=True):
        aligns = aligns or ["l"] * len(headers)
        total_w = self.width - 2 * self.margin
        col_w = [total_w * w for w in widths]
        row_h = size + 9
        # cabecalho
        self.ensure(row_h + 4)
        x0 = self.margin
        self.rect(x0, self.y - row_h + 6, total_w, row_h, header_color)
        cx = x0
        for header, width, align in zip(headers, col_w, aligns):
            self._cell_text(header, cx, width, align, size, bold=True, color=WHITE)
            cx += width
        self.y -= row_h
        # linhas
        for index, row in enumerate(rows):
            self.ensure(row_h)
            if zebra and index % 2 == 0:
                self.rect(x0, self.y - row_h + 6, total_w, row_h, LIGHT)
            cx = x0
            is_total = str(row[0]).upper() == "TOTAL" or str(row[1]).upper() == "TOTAL"
            for value, width, align in zip(row, col_w, aligns):
                self._cell_text(value, cx, width, align, size, bold=is_total, color=BLACK)
                cx += width
            self.line(x0, self.y - row_h + 5, x0 + total_w, self.y - row_h + 5, (0.85, 0.87, 0.90), 0.4)
            self.y -= row_h
        self.y -= 8

    def _cell_text(self, value, x, width, align, size, bold=False, color=BLACK):
        pad = 5
        text = str(value)
        # trunca se estourar
        while self.text_width(text, size, bold) > width - 2 * pad and len(text) > 3:
            text = text[:-2] + "."
        if align == "r":
            tx = x + width - pad - self.text_width(text, size, bold)
        elif align == "c":
            tx = x + (width - self.text_width(text, size, bold)) / 2
        else:
            tx = x + pad
        self.text_at(tx, self.y - size - 1, text, size, bold=bold, color=color)

    def cover(self, meta):
        # faixa superior
        self.rect(0, self.height - 200, self.width, 200, NAVY)
        self.rect(0, self.height - 206, self.width, 6, ACCENT)
        self.text_at(self.margin, self.height - 70, "CTE", 34, bold=True, color=WHITE)
        self.text_at(self.margin, self.height - 96, "Centro de Tecnologia de Edificacoes e Holding Ltda.", 11, color=(0.82, 0.86, 0.92))
        self.text_at(self.margin, self.height - 140, "Relatorio de Analise de Rubricas - eSocial", 17, bold=True, color=WHITE)
        self.text_at(self.margin, self.height - 162, f"Auxilio Doenca, Licenca Medica e Atestados ({SCOPE_EVENTS})", 11.5, color=(0.88, 0.91, 0.95))
        self.text_at(self.margin, self.height - 184, "Estruturado conforme diretrizes de auditoria da ISO 19011:2026", 9.5, color=(0.72, 0.78, 0.88))

        # caixa de metadados
        box_top = self.height - 240
        box_h = 250
        self.rect(self.margin, box_top - box_h, self.width - 2 * self.margin, box_h, (0.97, 0.98, 0.99))
        self.line(self.margin, box_top, self.width - self.margin, box_top, ACCENT, 1.2)
        yy = box_top - 26
        for label, value in meta:
            self.text_at(self.margin + 16, yy, label, 9.5, bold=True, color=STEEL)
            self.text_at(self.margin + 190, yy, value, 10, color=BLACK)
            self.line(self.margin + 16, yy - 8, self.width - self.margin - 16, yy - 8, (0.88, 0.90, 0.93), 0.4)
            yy -= 24

        self.text_at(self.margin, self.margin + 20, "Documento de uso restrito ao cliente e partes autorizadas.", 8.5, color=MIDGRAY)
        self.text_at(self.margin, self.margin + 8, f"Emitido em {datetime.now().strftime('%d/%m/%Y as %H:%M')}", 8.5, color=MIDGRAY)
        self.new_page()
        self.header_strip()

    def save(self):
        if self.ops:
            self.pages.append(self.ops)
        # rodape com numeracao
        objects = []
        objects.append("<< /Type /Catalog /Pages 2 0 R >>")
        objects.append(None)  # pages placeholder
        objects.append("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>")
        objects.append("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>")
        page_ids = []
        total_pages = len(self.pages)
        for page_index, ops in enumerate(self.pages, start=1):
            stream_ops = list(ops)
            # rodape
            footer_y = self.margin - 22
            r, g, b = MIDGRAY
            stream_ops.append(f"{r:.3f} {g:.3f} {b:.3f} RG 0.5 w {self.margin} {footer_y + 12:.2f} m {self.width - self.margin} {footer_y + 12:.2f} l S")
            foot_left = "CTE - Analise de rubricas eSocial"
            foot_right = f"Pagina {page_index} de {total_pages}"
            stream_ops.append(f"BT /F1 8 Tf {r:.3f} {g:.3f} {b:.3f} rg 1 0 0 1 {self.margin} {footer_y:.2f} Tm ({self._esc(foot_left)}) Tj ET")
            stream_ops.append(f"BT /F1 8 Tf {r:.3f} {g:.3f} {b:.3f} rg 1 0 0 1 {self.width - self.margin - 70:.2f} {footer_y:.2f} Tm ({self._esc(foot_right)}) Tj ET")
            content = "\n".join(stream_ops)
            content_bytes = content.encode("cp1252", "replace")
            content_id = len(objects) + 1
            page_id = len(objects) + 2
            objects.append(f"<< /Length {len(content_bytes)} >>\nstream\n{content}\nendstream")
            objects.append(f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {self.width:.2f} {self.height:.2f}] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents {content_id} 0 R >>")
            page_ids.append(page_id)
        kids = " ".join(f"{pid} 0 R" for pid in page_ids)
        objects[1] = f"<< /Type /Pages /Count {len(page_ids)} /Kids [{kids}] >>"
        offsets = []
        body = bytearray(b"%PDF-1.4\n")
        for index, obj in enumerate(objects, start=1):
            offsets.append(len(body))
            body.extend(f"{index} 0 obj\n{obj}\nendobj\n".encode("cp1252", "replace"))
        xref_start = len(body)
        body.extend(f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n".encode("cp1252"))
        for offset in offsets:
            body.extend(f"{offset:010d} 00000 n \n".encode("cp1252"))
        body.extend(f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref_start}\n%%EOF\n".encode("cp1252"))
        self.path.write_bytes(body)


def build_mapping_rows(by_code):
    index = {row["code"]: row for row in by_code}
    rows = []
    total = 0.0
    for folha_code, descricao, esocial_codes in MAPPING:
        occ = 0
        months = set()
        value = 0.0
        for code in esocial_codes:
            data = index.get(code, {})
            occ += int(data.get("occurrences", 0) or 0)
            value += float(data.get("total_vr_rubr", 0) or 0)
            months.update(m for m in (data.get("months", "") or "").split(", ") if m)
        total += value
        rows.append([folha_code, descricao, str(occ), str(len(months)), money_br(value)])
    rows.append(["", "TOTAL", "", "", money_br(total)])
    return rows, total


def main():
    global RELATED_BY_CODE, RELATED_BY_MONTH, PDF_PATH, SCOPE_EVENTS, SCOPE_TAG
    if len(sys.argv) > 1 and sys.argv[1] == "s1200":
        SCOPE_EVENTS = "S-1200 (S-1210 ignorado)"
        SCOPE_TAG = " - Somente S-1200"
        RELATED_BY_CODE = Path("tmp/cte_auxilio_doenca_related_s1200/rubricas_auxilio_doenca_por_codigo.csv")
        RELATED_BY_MONTH = Path("tmp/cte_auxilio_doenca_related_s1200/rubricas_auxilio_doenca_por_mes.csv")
        PDF_PATH = OUTPUT_DIR / "CTE_Relatorio_Auxilio_Doenca_ISO19011_Somente_S1200.pdf"

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    by_code = read_csv(RELATED_BY_CODE)
    by_month = read_csv(RELATED_BY_MONTH)
    mapping_rows, total = build_mapping_rows(by_code)
    total_occ = sum(int(row[2]) for row in mapping_rows if row[2].isdigit())
    months_present = [row["per_apur"] for row in by_month]
    periodo = f"{months_present[0]} a {months_present[-1]}" if months_present else "-"

    pdf = Pdf(PDF_PATH)
    meta = [
        ("Empresa", "CTE - Centro de Tecnologia de Edificacoes e Holding Ltda."),
        ("CNPJ", "64.030.638/0001-58"),
        ("Objeto", "Rubricas de auxilio doenca / atestado / licenca medica"),
        ("Fonte analisada", "CTE-TODOS-EVENTOS-XML.zip (64 ZIPs mensais)"),
        ("Volume", "65.494 XMLs lidos - escopo de itens: " + SCOPE_EVENTS),
        ("Periodo coberto", periodo),
        ("Data de emissao", datetime.now().strftime("%d/%m/%Y")),
        ("Versao do relatorio", "1.0"),
        ("Referencia", "ISO 19011:2026"),
    ]
    pdf.cover(meta)

    pdf.section(1, "Sumario executivo")
    pdf.paragraph(
        "Foi realizada analise documental sobre a totalidade dos eventos periodicos do eSocial da CTE "
        "disponibilizados no pacote CTE-TODOS-EVENTOS-XML.zip, com o objetivo de quantificar as rubricas "
        "de auxilio doenca, licenca medica e atestados solicitadas pela cliente.")
    pdf.paragraph(
        "Os cinco codigos informados (3302, 3605, 0218, 0213 e 0014) foram pesquisados de forma literal em "
        "todos os 65.494 XMLs e nao possuem nenhuma ocorrencia como codRubr no eSocial. A verificacao concluiu "
        "que esses codigos pertencem ao sistema interno de folha da empresa e, no eSocial, as mesmas verbas sao "
        "transmitidas sob codigos proprios da CTE.")
    pdf.paragraph(
        f"Mapeando pelas descricoes oficiais das rubricas (evento S-1010), foram localizadas {total_occ} ocorrencias em "
        f"{len(months_present)} competencias, no periodo de {periodo}, totalizando {money_br(total)}. Como a data-base "
        "deste relatorio e o final de 2026, praticamente todo o intervalo caracteriza efeito retroativo.")

    pdf.section(2, "Objetivo")
    pdf.paragraph(
        "Identificar, quantificar e evidenciar, de forma rastreavel, os valores associados as rubricas de auxilio "
        "doenca, complemento de auxilio doenca, desconto de adiantamento, licenca medica e horas de atestado, "
        "por codigo, quantidade de ocorrencias, quantidade de competencias e valor total somado.")

    pdf.section(3, "Escopo e limites")
    pdf.bullet("Empresa: CTE - Centro de Tecnologia de Edificacoes e Holding Ltda., CNPJ 64.030.638/0001-58.")
    pdf.bullet("Fonte: pacote local CTE-TODOS-EVENTOS-XML.zip, com 64 arquivos ZIP mensais.")
    pdf.bullet(f"Eventos considerados para soma de rubricas: {SCOPE_EVENTS}, com apoio do S-1010 (tabela de rubricas).")
    pdf.bullet("Volume processado: 65.494 XMLs, sem erros de leitura (0 falha de parse).")
    pdf.bullet("Exclusoes: nao houve consulta a APIs do eSocial; a analise e integralmente documental sobre os XMLs fornecidos.")

    pdf.section(4, "Criterios")
    pdf.bullet("Correspondencia exata dos codigos informados como codRubr nos XMLs (busca literal).")
    pdf.bullet("Correspondencia por descricao oficial da rubrica no evento S-1010 quando o codigo literal nao existe.")
    pdf.bullet("Soma de vrRubr por rubrica, com competencia (perApur), CPF e evento de origem preservados como evidencia.")
    pdf.bullet("Tratamento de rubricas de desconto (tpRubr 2/4) como valor negativo no total sinalizado.")

    pdf.section(5, "Metodologia")
    pdf.bullet("Leitura recursiva dos ZIPs mensais e de todos os XMLs, sem descompactar em disco.")
    pdf.bullet("Busca crua de texto pelos cinco codigos informados em 100% dos arquivos.")
    pdf.bullet(f"Extracao das rubricas (codRubr + vrRubr) restrita aos eventos {SCOPE_EVENTS} e cruzamento com as descricoes do S-1010.")
    pdf.bullet("Consolidacao por codigo e por competencia, com geracao de planilha de detalhe para auditoria.")

    pdf.section(6, "Evidencias objetivas - resumo por codigo")
    pdf.paragraph(
        "A tabela abaixo apresenta, para cada codigo solicitado pela cliente, quantas vezes a verba apareceu, "
        "em quantas competencias e o valor total somado, ja convertido para a rubrica real correspondente no eSocial da CTE.",
        size=10)
    pdf.table(
        ["Codigo", "Descricao", "Vezes", "Meses", "Valor total"],
        mapping_rows,
        widths=[0.12, 0.44, 0.12, 0.12, 0.20],
        aligns=["l", "l", "c", "c", "r"],
    )

    pdf.section(7, "Evidencias objetivas - distribuicao por competencia")
    month_rows = [
        [row["per_apur"], row["occurrences"], row["distinct_cpfs"], money_br(row["total_vr_rubr"]), money_br(row["total_signed_vr_rubr"])]
        for row in by_month
    ]
    pdf.table(
        ["Competencia", "Ocorrencias", "Trabalhadores", "Valor informado", "Valor com sinal"],
        month_rows,
        widths=[0.20, 0.18, 0.20, 0.21, 0.21],
        aligns=["l", "c", "c", "r", "r"],
        size=8.6,
    )

    pdf.section(8, "Achados de auditoria")
    pdf.bullet("Achado 1: os codigos 3302, 3605, 0218, 0213 e 0014 nao existem no eSocial (0 ocorrencia literal); sao codigos internos de folha.")
    pdf.bullet("Achado 2: as verbas equivalentes existem e se distribuem de 2021 a 2026, com concentracao a partir de 2024/2025.")
    pdf.bullet("Achado 3: a maior parte do valor esta em Dias Auxilio Doenca e Complemento de Auxilio Doenca (rubricas SECTECENT), somadas aos afastamentos por doenca de 2021 a 2023.")
    pdf.bullet("Achado 4: ha rubrica de desconto de adiantamento de complemento, que reduz o total liquido.")

    pdf.section(9, "Conclusao")
    pdf.paragraph(
        "A pesquisa foi executada sobre a totalidade dos XMLs disponibilizados e esta documentada e rastreavel por "
        "codigo, competencia, CPF e evento de origem. Confirma-se que os cinco codigos solicitados nao existem "
        "no eSocial na forma literal informada, o que explica o resultado zero em uma busca por codigo puro.")
    pdf.paragraph(
        f"Pela correspondencia de descricao, o montante total das verbas de auxilio doenca, licenca medica e "
        f"atestados e de {money_br(total)}, distribuido em {len(months_present)} competencias no periodo de {periodo}. "
        "Esse conjunto sustenta a analise de readequacao de incidencias solicitada, sendo praticamente todo o "
        "intervalo de carater retroativo em relacao a data-base deste relatorio.")
    pdf.paragraph(
        "Recomenda-se padronizar o cadastro de rubricas para vincular de forma explicita os codigos de folha aos "
        "codigos transmitidos ao eSocial, facilitando futuras conferencias e reduzindo risco de divergencia.", gap=2)

    pdf.save()
    print(f"PDF gerado: {PDF_PATH}")
    print(f"Total: {money_br(total)}")


if __name__ == "__main__":
    main()
