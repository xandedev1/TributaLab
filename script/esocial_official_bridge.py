import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path

import requests
import signxml
from lxml import etree
from signxml import XMLSigner

LEGACY_ROOT = Path(r"C:\Users\xandao\Documents\GitHub\Easy-Social\python-scripts")
if str(LEGACY_ROOT) not in sys.path:
    sys.path.insert(0, str(LEGACY_ROOT))

from db_config import LOCAL_DB_CONFIG  # noqa: E402
from esocial.certificate_manager import CertificateManager  # noqa: E402
from esocial.esocial_client import ESocialClient  # noqa: E402
from esocial.soap_builder import SOAPEnvelopeBuilder  # noqa: E402
from esocial.xml_signer import S1010XMLSigner  # noqa: E402
import psycopg2  # noqa: E402


DEFAULT_COMPANY_CNPJ = "64030638000158"
IDENT_TABELA_XSD_BASENAME = "ConsultaIdentificadoresEventosTabela-v1_0_0.xsd"


def clean_digits(value):
    return re.sub(r"\D", "", value or "")


def load_active_certificate():
    rails_pfx_path = os.environ.get("TRIBUTALAB_ESOCIAL_PFX_PATH")
    rails_password = os.environ.get("TRIBUTALAB_ESOCIAL_PFX_PASSWORD")
    if rails_pfx_path and rails_password:
        with open(rails_pfx_path, "rb") as file:
            pfx_data = file.read()
        return {
            "holder_cnpj": os.environ.get("TRIBUTALAB_ESOCIAL_HOLDER_DOCUMENT"),
            "cert_path": rails_pfx_path,
            "pfx_data": pfx_data,
            "password": rails_password,
        }

    conn = psycopg2.connect(**LOCAL_DB_CONFIG)
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT cnpj, arquivo_path, senha_encrypted "
                "FROM certificados_a1 WHERE ativo = TRUE "
                "ORDER BY created_at DESC LIMIT 1"
            )
            row = cursor.fetchone()
    finally:
        conn.close()

    if not row:
        raise RuntimeError("Nenhum certificado A1 ativo encontrado no legado Easy-Social")

    holder_cnpj, cert_path, encrypted_password = row
    with open(cert_path, "rb") as file:
        pfx_data = file.read()
    password = CertificateManager.decrypt_password(encrypted_password)
    return {
        "holder_cnpj": holder_cnpj,
        "cert_path": cert_path,
        "pfx_data": pfx_data,
        "password": password,
    }


def _pem_blocks_from_openssl(pfx_data, password):
    with tempfile.NamedTemporaryFile(delete=False, suffix=".pfx") as temp_pfx:
        temp_pfx.write(pfx_data)
        temp_pfx.flush()
        temp_pfx_path = temp_pfx.name

    env = os.environ.copy()
    env["TRIBUTALAB_ESOCIAL_OPENSSL_PASSWORD"] = password
    try:
        completed = subprocess.run(
            [
                "openssl",
                "pkcs12",
                "-legacy",
                "-in",
                temp_pfx_path,
                "-nodes",
                "-passin",
                "env:TRIBUTALAB_ESOCIAL_OPENSSL_PASSWORD",
            ],
            env=env,
            capture_output=True,
            check=False,
        )
    finally:
        try:
            os.unlink(temp_pfx_path)
        except OSError:
            pass

    if completed.returncode != 0:
        detail = completed.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(f"openssl pkcs12 falhou ao abrir o PFX: {detail}")

    pem = completed.stdout
    certs = re.findall(
        rb"-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----",
        pem,
        flags=re.S,
    )
    key_match = re.search(
        rb"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----",
        pem,
        flags=re.S,
    )
    if not certs or not key_match:
        raise RuntimeError("openssl nao retornou certificado e chave privada em PEM")

    return certs[0], key_match.group(0)


def _cert_key_pem(pfx_data, password):
    try:
        return ESocialClient._extrair_pem(pfx_data, password)
    except Exception:
        return _pem_blocks_from_openssl(pfx_data, password)


def _sign_inner_xml(inner_xml, pfx_data, password):
    try:
        signed = S1010XMLSigner.assinar(inner_xml.encode("utf-8"), pfx_data, password)
        return signed.decode("utf-8") if isinstance(signed, bytes) else signed
    except Exception:
        cert_pem, key_pem = _cert_key_pem(pfx_data, password)
        root = etree.fromstring(inner_xml.encode("utf-8"))
        signer = XMLSigner(
            method=signxml.methods.enveloped,
            signature_algorithm="rsa-sha256",
            digest_algorithm="sha256",
            c14n_algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315",
        )
        signed_root = signer.sign(root, key=key_pem, cert=cert_pem)
        return etree.tostring(signed_root, xml_declaration=True, encoding="UTF-8").decode("utf-8")


def _requests_verify_arg():
    if os.environ.get("TRIBUTALAB_ESOCIAL_VERIFY_TLS") == "0":
        return False
    return os.environ.get("REQUESTS_CA_BUNDLE") or True


def _fazer_request_assinado_verificado(inner_xml, montar_soap_fn, url, headers, pfx_data, password):
    try:
        inner_str = _sign_inner_xml(inner_xml, pfx_data, password)
        soap = montar_soap_fn(inner_str)
        cert_pem, key_pem = _cert_key_pem(pfx_data, password)
        _dump_outgoing_xml(inner_str, soap)
    except Exception as error:
        raise RuntimeError(f"PRE_REQUEST: {error}")

    temp_cert = tempfile.NamedTemporaryFile(mode="wb", delete=False, suffix=".pem")
    temp_key = tempfile.NamedTemporaryFile(mode="wb", delete=False, suffix=".pem")
    try:
        temp_cert.write(cert_pem)
        temp_cert.flush()
        temp_cert.close()
        temp_key.write(key_pem)
        temp_key.flush()
        temp_key.close()

        response = requests.post(
            url=url,
            data=soap.encode("utf-8"),
            headers=headers,
            cert=(temp_cert.name, temp_key.name),
            verify=_requests_verify_arg(),
            timeout=120,
        )
        if response.status_code >= 400:
            preview = re.sub(r"\s+", " ", response.text or "").strip()[:800]
            raise RuntimeError(f"HTTP {response.status_code}: {preview}")
        return response.text
    finally:
        for file_path in (temp_cert.name, temp_key.name):
            try:
                os.unlink(file_path)
            except OSError:
                pass


def _dump_outgoing_xml(inner_xml, soap_xml):
    dump_dir = os.environ.get("TRIBUTALAB_ESOCIAL_DUMP_REQUEST_DIR")
    if not dump_dir:
        return

    path = Path(dump_dir)
    path.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
    write_text(path / f"request_inner_signed_{timestamp}.xml", inner_xml)
    write_text(path / f"request_soap_{timestamp}.xml", soap_xml)


ESocialClient._fazer_request_assinado = staticmethod(_fazer_request_assinado_verificado)


def active_certificate_status(_args):
    certificate = load_active_certificate()

    from cryptography import x509
    from cryptography.hazmat.primitives.serialization import pkcs12

    private_key, parsed_certificate, _ = pkcs12.load_key_and_certificates(
        certificate["pfx_data"],
        certificate["password"].encode("utf-8"),
    )
    if parsed_certificate is None or private_key is None:
        raise RuntimeError("PFX ativo nao contem certificado e chave privada")

    subject = parsed_certificate.subject.rfc4514_string()
    issuer = parsed_certificate.issuer.rfc4514_string()
    extensions_text = " ".join(str(extension.value) for extension in parsed_certificate.extensions)
    identity_text = " ".join([subject, issuer, extensions_text])
    cnpjs = sorted(set(re.findall(r"\b\d{14}\b", identity_text)))
    cpfs = sorted(set(re.findall(r"\b\d{11}\b", identity_text)))
    common_names = parsed_certificate.subject.get_attributes_for_oid(x509.NameOID.COMMON_NAME)

    return {
        "operation": "cert-status",
        "official_request_attempted": False,
        "consumed_query": False,
        "success": True,
        "holder_cnpj": certificate["holder_cnpj"],
        "cert_path": certificate["cert_path"],
        "file_sha256": hashlib.sha256(certificate["pfx_data"]).hexdigest(),
        "subject": subject,
        "issuer": issuer,
        "common_name": common_names[0].value if common_names else None,
        "serial_number": str(parsed_certificate.serial_number),
        "not_before": parsed_certificate.not_valid_before_utc.isoformat(),
        "not_after": parsed_certificate.not_valid_after_utc.isoformat(),
        "cnpjs_found": cnpjs,
        "cpfs_found": cpfs,
    }


def write_text(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content or "", encoding="utf-8")
    return str(path)


def _find_ident_tabela_xsd():
    configured = os.environ.get("TRIBUTALAB_ESOCIAL_IDENT_TABELA_XSD")
    if configured:
        path = Path(configured)
        if path.exists():
            return path

    repo_root = Path(__file__).resolve().parents[1]
    versioned_path = repo_root / "config" / "esocial" / "xsd" / IDENT_TABELA_XSD_BASENAME
    if versioned_path.exists():
        return versioned_path

    root = repo_root / "tmp" / "esocial_docs"
    matches = sorted(root.rglob(IDENT_TABELA_XSD_BASENAME)) if root.exists() else []
    return matches[0] if matches else None


def _validate_ident_tabela_xml(xml_text):
    xsd_path = _find_ident_tabela_xsd()
    if not xsd_path:
        return {
            "xsd_valid": False,
            "xsd_path": None,
            "xsd_errors": [f"XSD nao encontrado: {IDENT_TABELA_XSD_BASENAME}"],
        }

    try:
        parser = etree.XMLParser(resolve_entities=False, no_network=True)
        schema = etree.XMLSchema(etree.parse(str(xsd_path), parser))
        document = etree.fromstring(xml_text.encode("utf-8"), parser)
        valid = schema.validate(document)
        return {
            "xsd_valid": bool(valid),
            "xsd_path": str(xsd_path),
            "xsd_errors": [str(error) for error in schema.error_log],
        }
    except Exception as error:
        return {
            "xsd_valid": False,
            "xsd_path": str(xsd_path),
            "xsd_errors": [str(error)],
        }


def build_identificadores_tabela(args):
    certificate = load_active_certificate()
    company_cnpj = clean_digits(args.company_cnpj or DEFAULT_COMPANY_CNPJ)
    empregador = {"tpInsc": 1, "nrInsc": company_cnpj}
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    requested_at = datetime.now().isoformat(timespec="seconds")
    unsigned_inner = SOAPEnvelopeBuilder.inner_consulta_ident_tabela(
        empregador=empregador,
        tp_evt=args.event_code,
        ch_evt=args.event_key,
        dt_ini=args.start,
        dt_fim=args.end,
    )
    signed_inner = _sign_inner_xml(unsigned_inner, certificate["pfx_data"], certificate["password"])
    soap = SOAPEnvelopeBuilder.montar_consulta_ident_tabela(signed_inner)
    validation = _validate_ident_tabela_xml(signed_inner)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    prefix = f"dry_run_ident_tabela_{args.event_code}_{timestamp}"
    unsigned_path = write_text(output_dir / f"{prefix}_inner_unsigned.xml", unsigned_inner)
    signed_path = write_text(output_dir / f"{prefix}_inner_signed.xml", signed_inner)
    soap_path = write_text(output_dir / f"{prefix}_soap.xml", soap)

    return {
        "operation": "build_identificadores_tabela",
        "official_request_attempted": False,
        "consumed_query": False,
        "requested_at": requested_at,
        "event_code": args.event_code,
        "event_key": args.event_key,
        "start": args.start,
        "end": args.end,
        "company_cnpj": company_cnpj,
        "certificate_holder_cnpj": certificate["holder_cnpj"],
        "endpoint": SOAPEnvelopeBuilder.url_identificadores(args.production),
        "soap_action": SOAPEnvelopeBuilder.headers_ident_tabela()["SOAPAction"],
        "success": bool(validation["xsd_valid"]),
        "inner_unsigned_path": unsigned_path,
        "inner_signed_path": signed_path,
        "soap_path": soap_path,
        **validation,
    }


def consultar_identificadores_empregador(args):
    certificate = load_active_certificate()
    company_cnpj = clean_digits(args.company_cnpj or DEFAULT_COMPANY_CNPJ)
    empregador = {"tpInsc": 1, "nrInsc": company_cnpj}
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    requested_at = datetime.now().isoformat(timespec="seconds")
    result = ESocialClient.consultar_identificadores_empregador(
        tp_evt=args.event_code,
        per_apur=args.per_apur,
        pfx_data=certificate["pfx_data"],
        password=certificate["password"],
        empregador=empregador,
        producao=args.production,
    )

    raw_xml_path = None
    if result.get("xml_resposta"):
        raw_xml_path = write_text(
            output_dir / f"ident_{args.event_code}_{args.per_apur}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xml",
            result.get("xml_resposta"),
        )

    payload = {
        "operation": "consultar_identificadores_empregador",
        "official_request_attempted": True,
        "consumed_query": True,
        "requested_at": requested_at,
        "event_code": args.event_code,
        "per_apur": args.per_apur,
        "company_cnpj": company_cnpj,
        "certificate_holder_cnpj": certificate["holder_cnpj"],
        "success": bool(result.get("sucesso")),
        "codigo_resposta": result.get("codigo_resposta"),
        "descricao": result.get("descricao"),
        "erro": result.get("erro"),
        "event_count": len(result.get("eventos") or []),
        "events": result.get("eventos") or [],
        "raw_xml_path": raw_xml_path,
    }
    return payload


def consultar_identificadores_tabela(args):
    certificate = load_active_certificate()
    company_cnpj = clean_digits(args.company_cnpj or DEFAULT_COMPANY_CNPJ)
    empregador = {"tpInsc": 1, "nrInsc": company_cnpj}
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    requested_at = datetime.now().isoformat(timespec="seconds")
    result = ESocialClient.consultar_identificadores_tabela(
        tp_evt=args.event_code,
        ch_evt=args.event_key,
        dt_ini=args.start,
        dt_fim=args.end,
        pfx_data=certificate["pfx_data"],
        password=certificate["password"],
        empregador=empregador,
        producao=args.production,
    )

    raw_xml_path = None
    if result.get("xml_resposta"):
        raw_xml_path = write_text(
            output_dir / f"ident_tabela_{args.event_code}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xml",
            result.get("xml_resposta"),
        )

    payload = {
        "operation": "consultar_identificadores_tabela",
        "official_request_attempted": True,
        "consumed_query": True,
        "requested_at": requested_at,
        "event_code": args.event_code,
        "event_key": args.event_key,
        "start": args.start,
        "end": args.end,
        "company_cnpj": company_cnpj,
        "certificate_holder_cnpj": certificate["holder_cnpj"],
        "success": bool(result.get("sucesso")),
        "codigo_resposta": result.get("codigo_resposta"),
        "descricao": result.get("descricao"),
        "erro": result.get("erro"),
        "event_count": len(result.get("eventos") or []),
        "events": result.get("eventos") or [],
        "raw_xml_path": raw_xml_path,
    }
    return payload


def solicitar_download_por_id(args):
    certificate = load_active_certificate()
    company_cnpj = clean_digits(args.company_cnpj or DEFAULT_COMPANY_CNPJ)
    empregador = {"tpInsc": 1, "nrInsc": company_cnpj}
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    ids = [item.strip() for item in args.ids.split(",") if item.strip()]
    requested_at = datetime.now().isoformat(timespec="seconds")
    result = ESocialClient.solicitar_download_por_id(
        ids=ids,
        pfx_data=certificate["pfx_data"],
        password=certificate["password"],
        empregador=empregador,
        producao=args.production,
    )

    raw_xml_path = None
    if result.get("xml_resposta"):
        raw_xml_path = write_text(
            output_dir / f"download_ids_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xml",
            result.get("xml_resposta"),
        )

    event_xml_paths = []
    for index, arquivo in enumerate(result.get("arquivos") or [], start=1):
        event_xml = arquivo.get("evento_xml")
        if event_xml:
            event_xml_paths.append(
                write_text(output_dir / f"evento_{index:03d}.xml", event_xml)
            )

    return {
        "operation": "solicitar_download_por_id",
        "official_request_attempted": True,
        "consumed_query": True,
        "requested_at": requested_at,
        "company_cnpj": company_cnpj,
        "certificate_holder_cnpj": certificate["holder_cnpj"],
        "success": bool(result.get("sucesso")),
        "codigo_resposta": result.get("codigo_resposta"),
        "descricao": result.get("descricao"),
        "erro": result.get("erro"),
        "arquivo_count": len(result.get("arquivos") or []),
        "raw_xml_path": raw_xml_path,
        "event_xml_paths": event_xml_paths,
    }


def solicitar_download_por_recibo(args):
    certificate = load_active_certificate()
    company_cnpj = clean_digits(args.company_cnpj or DEFAULT_COMPANY_CNPJ)
    empregador = {"tpInsc": 1, "nrInsc": company_cnpj}
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    receipts = [item.strip() for item in args.receipts.split(",") if item.strip()]
    requested_at = datetime.now().isoformat(timespec="seconds")
    result = ESocialClient.solicitar_download_por_nrrecibo(
        nr_recibos=receipts,
        pfx_data=certificate["pfx_data"],
        password=certificate["password"],
        empregador=empregador,
        producao=args.production,
    )

    raw_xml_path = None
    if result.get("xml_resposta"):
        raw_xml_path = write_text(
            output_dir / f"download_recibos_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xml",
            result.get("xml_resposta"),
        )

    event_xml_paths = []
    for index, arquivo in enumerate(result.get("arquivos") or [], start=1):
        event_xml = arquivo.get("evento_xml")
        if event_xml:
            event_xml_paths.append(
                write_text(output_dir / f"evento_recibo_{index:03d}.xml", event_xml)
            )

    return {
        "operation": "solicitar_download_por_recibo",
        "official_request_attempted": True,
        "consumed_query": True,
        "requested_at": requested_at,
        "company_cnpj": company_cnpj,
        "certificate_holder_cnpj": certificate["holder_cnpj"],
        "success": bool(result.get("sucesso")),
        "codigo_resposta": result.get("codigo_resposta"),
        "descricao": result.get("descricao"),
        "erro": result.get("erro"),
        "arquivo_count": len(result.get("arquivos") or []),
        "raw_xml_path": raw_xml_path,
        "event_xml_paths": event_xml_paths,
    }


def main():
    parser = argparse.ArgumentParser(description="Ponte oficial eSocial para TributaLab")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("cert-status")

    ident = subparsers.add_parser("ident-empregador")
    ident.add_argument("--event-code", required=True)
    ident.add_argument("--per-apur", required=True)
    ident.add_argument("--company-cnpj", default=DEFAULT_COMPANY_CNPJ)
    ident.add_argument("--output-dir", required=True)
    ident.add_argument("--production", action="store_true")

    ident_table = subparsers.add_parser("ident-tabela")
    ident_table.add_argument("--event-code", required=True)
    ident_table.add_argument("--event-key")
    ident_table.add_argument("--start")
    ident_table.add_argument("--end")
    ident_table.add_argument("--company-cnpj", default=DEFAULT_COMPANY_CNPJ)
    ident_table.add_argument("--output-dir", required=True)
    ident_table.add_argument("--production", action="store_true")

    build_ident_table = subparsers.add_parser("build-ident-tabela")
    build_ident_table.add_argument("--event-code", required=True)
    build_ident_table.add_argument("--event-key")
    build_ident_table.add_argument("--start")
    build_ident_table.add_argument("--end")
    build_ident_table.add_argument("--company-cnpj", default=DEFAULT_COMPANY_CNPJ)
    build_ident_table.add_argument("--output-dir", required=True)
    build_ident_table.add_argument("--production", action="store_true")

    download = subparsers.add_parser("download-ids")
    download.add_argument("--ids", required=True)
    download.add_argument("--company-cnpj", default=DEFAULT_COMPANY_CNPJ)
    download.add_argument("--output-dir", required=True)
    download.add_argument("--production", action="store_true")

    download_receipts = subparsers.add_parser("download-recibos")
    download_receipts.add_argument("--receipts", required=True)
    download_receipts.add_argument("--company-cnpj", default=DEFAULT_COMPANY_CNPJ)
    download_receipts.add_argument("--output-dir", required=True)
    download_receipts.add_argument("--production", action="store_true")

    args = parser.parse_args()

    try:
        if args.command == "cert-status":
            payload = active_certificate_status(args)
        elif args.command == "ident-empregador":
            payload = consultar_identificadores_empregador(args)
        elif args.command == "ident-tabela":
            payload = consultar_identificadores_tabela(args)
        elif args.command == "build-ident-tabela":
            payload = build_identificadores_tabela(args)
        elif args.command == "download-ids":
            payload = solicitar_download_por_id(args)
        elif args.command == "download-recibos":
            payload = solicitar_download_por_recibo(args)
        else:
            raise RuntimeError(f"Comando nao suportado: {args.command}")
    except Exception as error:
        payload = {
            "operation": args.command,
            "official_request_attempted": False,
            "consumed_query": False,
            "success": False,
            "erro": str(error),
        }

    print(json.dumps(payload, ensure_ascii=True))


if __name__ == "__main__":
    main()