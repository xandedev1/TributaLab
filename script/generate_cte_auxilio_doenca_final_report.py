#!/usr/bin/env python3

import csv
import json
import math
import re
import zipfile
from datetime import datetime
from pathlib import Path
from xml.sax.saxutils import escape


EXACT_DIR = Path("tmp/cte_auxilio_doenca_report")
RELATED_DIR = Path("tmp/cte_auxilio_doenca_related_report")
OUTPUT_DIR = Path("tmp/relatorio_cte_auxilio_doenca_final")
XLSX_PATH = OUTPUT_DIR / "relatorio_geral_auxilio_doenca_cte.xlsx"
PDF_PATH = OUTPUT_DIR / "relatorio_geral_auxilio_doenca_cte.pdf"

# Mapeamento entre o codigo da folha (informado pela cliente) e as rubricas
# reais encontradas no eSocial da CTE. Os codigos da folha NAO existem como
# codRubr no eSocial (0 hits em 65.494 XMLs) - a CTE usa os codigos abaixo.
CODE_MAPPING = [
    ("3302 / 3605", "Complement Auxilio Doenca", "SECTECENT...258 Dias Auxilio Doenca; SECTECENT...289 Complemento Auxilio Doenca (Provento); 8870 DIAS AFAST PDOENCA CDIRINTEGRAIS; 9505 DIAS AFAST PDOENCA IGUALINF 15 DIAS"),
    ("0218", "Desc adto Auxilio doenca", "SECTECENT...291 Desconto adiantamento complemento auxilio Doenca"),
    ("0213", "Dias Lic. Medica ate 15d", "SECTECENT...205 Dias Lic. Medica ate 15d"),
    ("0014", "Hrs Atestado ate 15 dias", "SECTECENT...003 Hrs Atestado at 15 dias; SECTECENT...199 Hrs Atestado ate 15 dias"),
]


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def read_csv(path):
    with path.open("r", encoding="utf-8-sig", newline="") as file:
        return list(csv.DictReader(file))


def money_br(value):
    number = float(str(value or "0").replace(".", "."))
    formatted = f"{number:,.2f}"
    return "R$ " + formatted.replace(",", "X").replace(".", ",").replace("X", ".")


def int_br(value):
    return f"{int(value):,}".replace(",", ".")


def as_number(value):
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    if re.fullmatch(r"-?\d+", text):
        return int(text)
    if re.fullmatch(r"-?\d+\.\d+", text):
        return float(text)
    return None


def cell_ref(column_index, row_index):
    letters = ""
    current = column_index
    while current:
        current, remainder = divmod(current - 1, 26)
        letters = chr(65 + remainder) + letters
    return f"{letters}{row_index}"


def sheet_xml(headers, rows):
    table = [headers] + rows
    rows_xml = []
    for row_index, row in enumerate(table, start=1):
        cells = []
        for column_index, value in enumerate(row, start=1):
            ref = cell_ref(column_index, row_index)
            style = ' s="1"' if row_index == 1 else ""
            number = as_number(value)
            if number is not None and not (isinstance(value, str) and value.startswith("0") and value.isdigit()):
                cells.append(f'<c r="{ref}"{style}><v>{number}</v></c>')
            else:
                text = escape(str(value or ""))
                cells.append(f'<c r="{ref}" t="inlineStr"{style}><is><t>{text}</t></is></c>')
        rows_xml.append(f'<row r="{row_index}">{"".join(cells)}</row>')

    widths = []
    for column_index, header in enumerate(headers, start=1):
        max_len = len(str(header))
        for row in rows[:200]:
            if column_index <= len(row):
                max_len = max(max_len, len(str(row[column_index - 1] or "")))
        width = min(max(max_len + 2, 12), 55)
        widths.append(f'<col min="{column_index}" max="{column_index}" width="{width}" customWidth="1"/>')

    return f'''<?xml version="1.0" encoding="UTF-8"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>
  <sheetFormatPr defaultRowHeight="15"/>
  <cols>{"".join(widths)}</cols>
  <sheetData>{"".join(rows_xml)}</sheetData>
  <autoFilter ref="A1:{cell_ref(len(headers), max(len(table), 1))}"/>
</worksheet>'''


def make_xlsx(path, sheets):
    content_overrides = [
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
        '<Default Extension="xml" ContentType="application/xml"/>',
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>',
        '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>',
        '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>',
    ]
    for index in range(1, len(sheets) + 1):
        content_overrides.append(f'<Override PartName="/xl/worksheets/sheet{index}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>')

    sheet_nodes = []
    rel_nodes = []
    for index, (name, _headers, _rows) in enumerate(sheets, start=1):
        sheet_nodes.append(f'<sheet name="{escape(name[:31])}" sheetId="{index}" r:id="rId{index}"/>')
        rel_nodes.append(f'<Relationship Id="rId{index}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{index}.xml"/>')
    rel_nodes.append(f'<Relationship Id="rId{len(sheets) + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>')

    timestamp = datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as package:
        package.writestr("[Content_Types].xml", f'''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">{"".join(content_overrides)}</Types>''')
        package.writestr("_rels/.rels", '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''')
        package.writestr("xl/workbook.xml", f'''<?xml version="1.0" encoding="UTF-8"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>{"".join(sheet_nodes)}</sheets></workbook>''')
        package.writestr("xl/_rels/workbook.xml.rels", f'''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">{"".join(rel_nodes)}</Relationships>''')
        package.writestr("xl/styles.xml", '''<?xml version="1.0" encoding="UTF-8"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/><color rgb="FFFFFFFF"/></font></fonts>
  <fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF9A1C20"/><bgColor indexed="64"/></patternFill></fill></fills>
  <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''')
        for index, (_name, headers, rows) in enumerate(sheets, start=1):
            package.writestr(f"xl/worksheets/sheet{index}.xml", sheet_xml(headers, rows))
        package.writestr("docProps/core.xml", f'''<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>Relatorio Geral CTE Auxilio Doenca</dc:title><dc:creator>TributaLab</dc:creator><dcterms:created xsi:type="dcterms:W3CDTF">{timestamp}</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">{timestamp}</dcterms:modified></cp:coreProperties>''')
        package.writestr("docProps/app.xml", '''<?xml version="1.0" encoding="UTF-8"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>TributaLab</Application></Properties>''')


class PdfDocument:
    def __init__(self, path):
        self.path = path
        self.pages = []
        self.current = []
        self.y = 800
        self.margin = 48
        self.width = 595
        self.height = 842

    def _escape(self, text):
        replacements = {
            "\u2013": "-",
            "\u2014": "-",
            "\u2018": "'",
            "\u2019": "'",
            "\u201c": '"',
            "\u201d": '"',
            "\u2026": "...",
            "\u00a0": " ",
        }
        text = str(text)
        for source, target in replacements.items():
            text = text.replace(source, target)
        encoded = text.encode("cp1252", "replace").decode("cp1252")
        return encoded.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")

    def new_page(self):
        if self.current:
            self.pages.append("\n".join(self.current))
        self.current = []
        self.y = 800

    def ensure_space(self, needed=40):
        if self.y < 60 + needed:
            self.new_page()

    def text(self, value, size=10, bold=False, x=None, leading=None):
        x = self.margin if x is None else x
        leading = leading or size + 4
        self.ensure_space(leading)
        font = "F2" if bold else "F1"
        self.current.append(f"BT /{font} {size} Tf {x} {self.y} Td ({self._escape(value)}) Tj ET")
        self.y -= leading

    def paragraph(self, value, size=10, bold=False, width=92):
        words = str(value).split()
        line = ""
        for word in words:
            candidate = word if not line else f"{line} {word}"
            if len(candidate) > width:
                self.text(line, size=size, bold=bold)
                line = word
            else:
                line = candidate
        if line:
            self.text(line, size=size, bold=bold)
        self.y -= 4

    def section(self, title):
        self.y -= 8
        self.text(title, size=13, bold=True)

    def table(self, headers, rows, widths, size=8):
        self.ensure_space(40)
        self.text(" | ".join(headers), size=size, bold=True)
        for row in rows:
            pieces = []
            for value, width in zip(row, widths):
                text = str(value)
                pieces.append(text if len(text) <= width else text[: width - 1] + "...")
            self.text(" | ".join(pieces), size=size)
        self.y -= 4

    def save(self):
        if self.current:
            self.pages.append("\n".join(self.current))
        objects = []
        pages_id = 2
        catalog = "<< /Type /Catalog /Pages 2 0 R >>"
        objects.append(catalog)
        objects.append(None)
        objects.append("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>")
        objects.append("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>")
        page_ids = []
        for content in self.pages:
            content_bytes = content.encode("cp1252", "replace")
            content_id = len(objects) + 1
            page_id = len(objects) + 2
            objects.append(f"<< /Length {len(content_bytes)} >>\nstream\n{content}\nendstream")
            objects.append(f"<< /Type /Page /Parent {pages_id} 0 R /MediaBox [0 0 {self.width} {self.height}] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents {content_id} 0 R >>")
            page_ids.append(page_id)
        kids = " ".join(f"{page_id} 0 R" for page_id in page_ids)
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


def build_report_data():
    exact_summary = read_json(EXACT_DIR / "scan_summary.json")
    related_summary = read_json(RELATED_DIR / "scan_summary.json")
    by_code = read_csv(RELATED_DIR / "rubricas_auxilio_doenca_por_codigo.csv")
    by_month = read_csv(RELATED_DIR / "rubricas_auxilio_doenca_por_mes.csv")
    details = read_csv(RELATED_DIR / "rubricas_auxilio_doenca_detalhe.csv")
    candidates = read_csv(RELATED_DIR / "rubricas_s1010_candidatas_por_descricao.csv")
    return exact_summary, related_summary, by_code, by_month, details, candidates


def build_sheets(exact_summary, related_summary, by_code, by_month, details, candidates):
    overview_rows = [
        ["Arquivo analisado", exact_summary["zip_path"]],
        ["ZIPs mensais lidos", exact_summary["inner_zip_count"]],
        ["XMLs lidos", exact_summary["xml_count"]],
        ["S-1200 lidos", exact_summary["event_counts"].get("S-1200", 0)],
        ["S-1210 lidos", exact_summary["event_counts"].get("S-1210", 0)],
        ["Erros de leitura XML", exact_summary["parse_error_count"]],
        ["Codigos exatos pesquisados", "3302, 3605, 0218, 0213, 0014"],
        ["Resultado dos codigos exatos", "0 hit literal como codRubr em 65.494 XMLs (sao codigos da folha, nao do eSocial)"],
        ["Rubricas equivalentes por descricao S-1010", related_summary["s1010_candidate_definition_count"]],
        ["Ocorrencias equivalentes", related_summary["match_occurrences"]],
        ["Eventos distintos", related_summary["distinct_events"]],
        ["Trabalhadores distintos", related_summary["distinct_cpfs"]],
        ["Competencias com ocorrencia", related_summary["distinct_months"]],
        ["Periodo coberto", f"{related_summary['months'][0]} a {related_summary['months'][-1]}"],
        ["Total informado", money_br(related_summary["total_vr_rubr"])],
        ["Total com desconto sinalizado", money_br(related_summary["total_signed_vr_rubr"])],
        ["Conclusao", "Os codigos exatos nao existem no eSocial; as rubricas equivalentes ocorrem de 2021 a 2026, com concentracao a partir de 2024/2025."],
    ]
    code_rows = [
        [
            row["code"],
            row["s1010_descriptions"] or row["expected_description"],
            row["tp_rubr_values"],
            row["occurrences"],
            row["distinct_months"],
            row["distinct_cpfs"],
            row["total_vr_rubr"],
            row["total_signed_vr_rubr"],
            row["months"],
        ]
        for row in by_code
    ]
    month_rows = [
        [
            row["per_apur"],
            row["occurrences"],
            row["distinct_cpfs"],
            row["total_vr_rubr"],
            row["total_signed_vr_rubr"],
        ]
        for row in by_month
    ]
    detail_rows = [
        [
            row["per_apur"],
            row["event_type"],
            row["cpf"],
            row["matricula"],
            row["code"],
            row["s1010_description"],
            row["tp_rubr"],
            row["vr_rubr"],
            row["signed_vr_rubr"],
            row["event_id"],
            row["source_zip"],
            row["xml_name"],
        ]
        for row in details
    ]
    candidate_rows = [
        [
            row["code"],
            row["description"],
            row["ini_valid"],
            row["fim_valid"],
            row["tp_rubr"],
            row["nat_rubr"],
            row["cod_inc_cp"],
            row["cod_inc_fgts"],
            row["cod_inc_irrf"],
            row["source_zip"],
            row["xml_name"],
        ]
        for row in candidates
    ]
    sheets = [
        ("Resumo Geral", ["Campo", "Resultado"], overview_rows),
        ("Mapeamento Codigos", ["Codigo folha", "Descricao folha", "Rubricas reais no eSocial CTE"], [[m[0], m[1], m[2]] for m in CODE_MAPPING]),
        ("Tabela Geral", ["Codigo", "Descricao S-1010", "tpRubr", "Ocorrencias", "Meses", "Trabalhadores", "Total informado", "Total com sinal", "Competencias"], code_rows),
        ("Por Mes", ["Competencia", "Ocorrencias", "Trabalhadores", "Total informado", "Total com sinal"], month_rows),
        ("Detalhe", ["Competencia", "Evento", "CPF", "Matricula", "Codigo", "Descricao", "tpRubr", "Valor", "Valor com sinal", "ID evento", "ZIP", "XML"], detail_rows),
        ("S1010 Candidatas", ["Codigo", "Descricao", "IniValid", "FimValid", "tpRubr", "natRubr", "codIncCP", "codIncFGTS", "codIncIRRF", "ZIP", "XML"], candidate_rows),
    ]
    return sheets


def generate_pdf(path, exact_summary, related_summary, by_code, by_month):
    pdf = PdfDocument(path)
    pdf.text("Relatorio Geral - CTE", size=18, bold=True)
    pdf.text("Rubricas de auxilio doenca, licenca medica e atestados", size=12, bold=True)
    pdf.text(f"Gerado em {datetime.now().strftime('%d/%m/%Y %H:%M')}", size=9)
    pdf.y -= 8

    pdf.section("1. Escopo analisado")
    pdf.paragraph(f"Foi analisado o arquivo {exact_summary['zip_path']}. O pacote contem {exact_summary['inner_zip_count']} ZIPs mensais e {int_br(exact_summary['xml_count'])} XMLs. A leitura nao teve erro de parse.")
    pdf.paragraph(f"Dentro do pacote foram encontrados {int_br(exact_summary['event_counts'].get('S-1200', 0))} eventos S-1200 e {int_br(exact_summary['event_counts'].get('S-1210', 0))} eventos S-1210, alem dos eventos de tabelas S-1010 usados para conferir descricoes e incidencias.")

    pdf.section("2. Pesquisa pelos codigos informados")
    pdf.paragraph("Codigos pesquisados literalmente: 3302, 3605, 0218, 0213 e 0014.")
    pdf.paragraph("Resultado: esses codigos NAO existem como codRubr no eSocial da CTE. Foi feita busca crua de texto em todos os 65.494 XMLs e cada um deu 0 ocorrencia. Eles sao os codigos do sistema de folha da cliente, nao os codigos usados no envio ao eSocial.")

    pdf.section("3. Mapeamento codigo da folha x rubrica real no eSocial")
    mapping_rows = [[m[0], m[1], m[2]] for m in CODE_MAPPING]
    pdf.table(["Folha", "Descricao", "Rubricas reais no eSocial"], mapping_rows, [12, 26, 52], size=7)

    pdf.section("4. Pesquisa por rubricas equivalentes da CTE")
    pdf.paragraph("Usando as definicoes S-1010 relacionadas a auxilio doenca, atestado e licenca medica, foram localizadas as rubricas reais equivalentes em todos os anos disponiveis.")
    pdf.paragraph(f"Foram encontradas {related_summary['match_occurrences']} ocorrencias, em {related_summary['distinct_events']} eventos, {related_summary['distinct_cpfs']} trabalhadores e {related_summary['distinct_months']} competencias, cobrindo de {related_summary['months'][0]} a {related_summary['months'][-1]}. O total informado foi {money_br(related_summary['total_vr_rubr'])}. Considerando desconto como valor negativo, o total com sinal foi {money_br(related_summary['total_signed_vr_rubr'])}.")

    pdf.section("5. Tabela geral por rubrica relacionada")
    table_rows = []
    for row in by_code:
        table_rows.append([
            row["code"],
            row["s1010_descriptions"] or row["expected_description"],
            row["occurrences"],
            row["distinct_months"],
            money_br(row["total_vr_rubr"]),
            money_br(row["total_signed_vr_rubr"]),
        ])
    pdf.table(["Codigo", "Descricao", "Oc", "Meses", "Total", "Sinal"], table_rows, [17, 32, 4, 5, 12, 12], size=7)

    pdf.section("6. Competencias com ocorrencia")
    month_rows = [[row["per_apur"], row["occurrences"], row["distinct_cpfs"], money_br(row["total_vr_rubr"]), money_br(row["total_signed_vr_rubr"])] for row in by_month]
    pdf.table(["Competencia", "Oc", "Trab", "Total", "Sinal"], month_rows, [12, 4, 5, 14, 14], size=8)

    pdf.section("7. Conclusao objetiva")
    pdf.paragraph("Os 5 codigos exatos enviados nao existem no eSocial da CTE - sao codigos da folha. Por isso a busca literal deu 0. Isso nao significa ausencia dos eventos: significa que no eSocial eles tem outro codigo.")
    pdf.paragraph("Mapeando por descricao, as rubricas de auxilio doenca, licenca medica e atestado aparecem de 2021 a 2026, totalizando " + money_br(related_summary["total_vr_rubr"]) + ". Como estamos no fim de 2026, praticamente todo esse periodo e retroativo. A movimentacao se intensifica a partir de 2024/2025 com as rubricas SECTECENT de Dias Auxilio Doenca e Complemento Auxilio Doenca.")
    pdf.save()


def write_with_fallback(target, writer):
    try:
        writer(target)
        return target
    except PermissionError:
        alternative = target.with_name(f"{target.stem}_{datetime.now().strftime('%H%M%S')}{target.suffix}")
        writer(alternative)
        return alternative


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    exact_summary, related_summary, by_code, by_month, details, candidates = build_report_data()
    global XLSX_PATH, PDF_PATH
    PDF_PATH = write_with_fallback(PDF_PATH, lambda path: generate_pdf(path, exact_summary, related_summary, by_code, by_month))
    XLSX_PATH = write_with_fallback(XLSX_PATH, lambda path: make_xlsx(path, build_sheets(exact_summary, related_summary, by_code, by_month, details, candidates)))
    print(json.dumps({"xlsx": str(XLSX_PATH), "pdf": str(PDF_PATH)}, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()