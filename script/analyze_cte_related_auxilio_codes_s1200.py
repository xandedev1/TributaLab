#!/usr/bin/env python3
"""Roda a analise das rubricas relacionadas de auxilio doenca considerando
APENAS eventos S-1200 (ignora S-1210), com nova varredura completa do ZIP."""

import importlib.util
import sys
from pathlib import Path


BASE_SCRIPT = Path(__file__).with_name("analyze_cte_auxilio_doenca_zip.py")
spec = importlib.util.spec_from_file_location("cte_auxilio_base", BASE_SCRIPT)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

RELATED_RUBRICS = {
    "8870": "DIAS AFAST PDOENCA CDIRINTEGRAIS",
    "9505": "DIAS AFAST PDOENCA IGUALINF 15 DIAS",
    "8869": "DIAS AFAST PACID TRABALHO CDIR INTEG",
    "SECTECENT200000000000000000003": "Hrs Atestado at 15 dias",
    "SECTECENT200000000000000000199": "Hrs Atestado ate 15 dias",
    "SECTECENT200000000000000000205": "Dias Lic. Medica ate 15d",
    "SECTECENT200000000000000000258": "Dias Auxilio Doenca",
    "SECTECENT200000000000000000288": "Complemento Auxilio Doenca (Informativo na folha)",
    "SECTECENT200000000000000000289": "Complemento Auxilio Doenca (Provento)",
    "SECTECENT200000000000000000291": "Desconto adiantamento complemento auxilio Doenca",
}


def main():
    zip_path = Path(sys.argv[1]) if len(sys.argv) > 1 else base.DEFAULT_ZIP
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("tmp/cte_auxilio_doenca_related_s1200")
    base.TARGET_RUBRICS.clear()
    base.TARGET_RUBRICS.update(RELATED_RUBRICS)
    base.ITEM_EVENT_TYPES = {"S-1200"}
    scan = base.scan_zip(zip_path)
    summary = base.write_outputs(output_dir, zip_path, scan)
    print(base.json.dumps(summary, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
