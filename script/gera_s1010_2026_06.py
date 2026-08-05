"""Gera os eventos S-1010 de 06/2026 para as rubricas que ainda apontam ao processo antigo."""

import json
import re
from pathlib import Path

from lxml import etree

NS = "http://www.esocial.gov.br/schema/evt/evtTabRubrica/v_S_01_03_00"
XSD = Path("tmp/esocial_xsd_s_1_3_20260701/evtTabRubrica.xsd")
PROCESSO_NOVO = "50064912020224036119"
PROCESSO_ANTIGO = "50064938720224036119"
NOVA_VALIDADE = "2026-06"
DESTINO = Path("storage/private/esocial/appa/s1010_2026-06")


def campo(xml: str, tag: str) -> str | None:
    m = re.search(rf"<{tag}>([^<]*)</{tag}>", xml)
    return m.group(1) if m else None


def monta(origem: str, sequencial: int) -> tuple[str, str]:
    dados = {
        t: campo(origem, t)
        for t in (
            "codRubr", "ideTabRubr", "dscRubr", "natRubr", "tpRubr",
            "codIncCP", "codIncIRRF", "codIncFGTS", "extDecisao", "codSusp",
        )
    }
    if campo(origem, "nrProc") != PROCESSO_ANTIGO:
        raise ValueError(f"{dados['codRubr']} nao aponta ao processo antigo")

    evento_id = f"ID1059690710000" + "00" + "20260731140000" + f"{sequencial:05d}"
    xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<eSocial xmlns="{NS}">
  <evtTabRubrica Id="{evento_id}">
    <ideEvento>
      <tpAmb>1</tpAmb>
      <procEmi>1</procEmi>
      <verProc>TributaLab 1.0</verProc>
    </ideEvento>
    <ideEmpregador>
      <tpInsc>1</tpInsc>
      <nrInsc>05969071</nrInsc>
    </ideEmpregador>
    <infoRubrica>
      <inclusao>
        <ideRubrica>
          <codRubr>{dados['codRubr']}</codRubr>
          <ideTabRubr>{dados['ideTabRubr']}</ideTabRubr>
          <iniValid>{NOVA_VALIDADE}</iniValid>
        </ideRubrica>
        <dadosRubrica>
          <dscRubr>{dados['dscRubr']}</dscRubr>
          <natRubr>{dados['natRubr']}</natRubr>
          <tpRubr>{dados['tpRubr']}</tpRubr>
          <codIncCP>{dados['codIncCP']}</codIncCP>
          <codIncIRRF>{dados['codIncIRRF']}</codIncIRRF>
          <codIncFGTS>{dados['codIncFGTS']}</codIncFGTS>
          <ideProcessoCP>
            <tpProc>2</tpProc>
            <nrProc>{PROCESSO_NOVO}</nrProc>
            <extDecisao>{dados['extDecisao']}</extDecisao>
            <codSusp>{dados['codSusp']}</codSusp>
          </ideProcessoCP>
        </dadosRubrica>
      </inclusao>
    </infoRubrica>
  </evtTabRubrica>
</eSocial>
"""
    return dados["codRubr"], xml


def valida(xml: str) -> list[str]:
    """Valida o conteudo do evento tornando a assinatura opcional, como no S-1020 preparado."""
    schema_src = XSD.read_text(encoding="utf-8").replace(
        '<xs:element ref="ds:Signature" />',
        '<xs:element ref="ds:Signature" minOccurs="0" />',
    )
    schema = etree.XMLSchema(etree.fromstring(schema_src.encode("utf-8"), base_url=str(XSD.resolve())))
    doc = etree.fromstring(xml.encode("utf-8"))
    if schema.validate(doc):
        return []
    return [f"linha {e.line}: {e.message}" for e in schema.error_log]


def main() -> None:
    origens = json.loads(Path("tmp/s1010_div_raw.json").read_text(encoding="utf-8"))
    DESTINO.mkdir(parents=True, exist_ok=True)

    for i, (id_evento, origem) in enumerate(sorted(origens.items()), start=1):
        cod, xml = monta(origem, i)
        erros = valida(xml)
        destino = DESTINO / f"S-1010_{cod}_{NOVA_VALIDADE}_UNSIGNED.xml"
        destino.write_text(xml, encoding="utf-8")
        estado = "VALIDO no XSD S-1.3" if not erros else f"ERROS: {erros}"
        print(f"{cod:8} | origem {id_evento} | {destino.name} | {estado}")


if __name__ == "__main__":
    main()
