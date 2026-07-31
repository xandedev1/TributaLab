const fs = require("fs");
const path = require("path");
const sharp = require(path.resolve(__dirname, "../../../tmp/auditor-fiscal-pptx-tools/node_modules/sharp"));
const PptxGenJS = require(path.resolve(__dirname, "../../../tmp/auditor-fiscal-pptx-tools/node_modules/pptxgenjs"));

const ROOT = __dirname;
const PREVIEW_DIR = path.join(ROOT, "preview");
const ASSET_DIR = path.join(ROOT, "recortes");
const OUTPUT_PATH = path.join(ROOT, "TributaLab_Auditor_Fiscal_Onboarding.pptx");
const SLIDE_W = 13.333;
const SLIDE_H = 7.5;
const PREVIEW_SCALE = 120;

const COLORS = {
  inkStrong: "0C292A",
  ink: "173A3B",
  inkSoft: "36595A",
  paper: "F5F2E9",
  paperDeep: "ECE8DC",
  white: "FFFEF9",
  line: "D8D5C9",
  muted: "738080",
  mint: "9BC8B5",
  mintDark: "4C8C78",
  coral: "D66E54",
  coralSoft: "F0C1B4",
  gold: "C99B52",
};

const FONT = "Bahnschrift";

const SOURCES = [
  "faturamento.png",
  "contas_a_receber.png",
  "cruzamento.png",
  "folha.png",
  "despesas.jpg",
  "explorador_despesas.jpg",
];

const CROPS = {
  capa: { source: "faturamento.png", left: 0, top: 0, width: 2376, height: 3050, ratio: 1.091, position: "north" },
  faturamento_kpis: { source: "faturamento.png", left: 430, top: 300, width: 1880, height: 378, ratio: 4.968, position: "north" },
  faturamento_retencoes: { source: "faturamento.png", left: 1560, top: 720, width: 750, height: 540, ratio: 1.145, position: "north", fit: "contain" },
  faturamento_tomadores: { source: "faturamento.png", left: 430, top: 1200, width: 1460, height: 950, ratio: 1.163, position: "north", fit: "contain" },
  receber_kpis: { source: "contas_a_receber.png", left: 430, top: 300, width: 1880, height: 412, ratio: 4.558, position: "north" },
  receber_clientes: { source: "contas_a_receber.png", left: 430, top: 1230, width: 1450, height: 928, ratio: 1.563, position: "north" },
  receber_contingencias: { source: "contas_a_receber.png", left: 1880, top: 1230, width: 430, height: 730, ratio: 0.589, position: "north" },
  cruzamento_filtros: { source: "cruzamento.png", left: 430, top: 0, width: 1880, height: 535, ratio: 3.507, position: "north" },
  cruzamento_resultado: { source: "cruzamento.png", left: 430, top: 950, width: 1880, height: 1600, ratio: 2.346 },
  cruzamento_tabela: { source: "cruzamento.png", left: 430, top: 2500, width: 1880, height: 1250, ratio: 5.154, position: "north" },
  folha_resumo: { source: "folha.png", left: 430, top: 300, width: 1880, height: 782, ratio: 2.406, position: "north" },
  folha_tabela: { source: "folha.png", left: 430, top: 2370, width: 1880, height: 450, ratio: 4.216, position: "north" },
  despesas_resumo: { source: "despesas.jpg", left: 400, top: 170, width: 1900, height: 820, ratio: 4.579 },
  despesas_fluxo: { source: "despesas.jpg", left: 400, top: 950, width: 1900, height: 1450, ratio: 2.433 },
  explorador_filtros: { source: "explorador_despesas.jpg", left: 430, top: 0, width: 1880, height: 550, ratio: 3.409, position: "north" },
  explorador_tabela: { source: "explorador_despesas.jpg", left: 430, top: 1100, width: 1880, height: 1600, ratio: 3.056, position: "north" },
};

async function prepareSourceOverviews() {
  fs.mkdirSync(PREVIEW_DIR, { recursive: true });

  await Promise.all(
    SOURCES.map(async (fileName) => {
      const sourcePath = path.join(ROOT, fileName);
      const outputPath = path.join(PREVIEW_DIR, `overview_${path.parse(fileName).name}.jpg`);

      await sharp(sourcePath)
        .resize({ width: 700 })
        .jpeg({ quality: 88 })
        .toFile(outputPath);
    }),
  );
}

async function prepareCrops() {
  fs.mkdirSync(ASSET_DIR, { recursive: true });

  await Promise.all(
    Object.entries(CROPS).map(async ([name, crop]) => {
      await sharp(path.join(ROOT, crop.source))
        .extract({ left: crop.left, top: crop.top, width: crop.width, height: crop.height })
        .resize({
          width: 1600,
          height: Math.round(1600 / crop.ratio),
          fit: crop.fit || "cover",
          position: crop.position || "centre",
          background: { r: 255, g: 254, b: 249 },
        })
        .jpeg({ quality: 92, chromaSubsampling: "4:4:4" })
        .toFile(path.join(ASSET_DIR, `${name}.jpg`));
    }),
  );
}

function xmlEscape(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function imageData(pathName) {
  return `data:image/jpeg;base64,${fs.readFileSync(pathName).toString("base64")}`;
}

class SlideBuilder {
  constructor(pptx, background = COLORS.paper) {
    this.slide = pptx.addSlide();
    this.elements = [];
    this.rect(0, 0, SLIDE_W, SLIDE_H, background);
  }

  rect(x, y, w, h, fill, line = null, radius = 0) {
    const shape = radius > 0 ? "roundRect" : "rect";
    this.slide.addShape(shape, {
      x,
      y,
      w,
      h,
      rectRadius: radius,
      fill: { color: fill },
      line: line ? { color: line.color, width: line.width || 1 } : { color: fill, transparency: 100 },
    });
    this.elements.push({ type: "rect", x, y, w, h, fill, line, radius });
  }

  text(value, x, y, w, h, options = {}) {
    const settings = {
      x,
      y,
      w,
      h,
      margin: 0,
      fontFace: FONT,
      fontSize: options.fontSize || 18,
      color: options.color || COLORS.ink,
      bold: Boolean(options.bold),
      align: options.align || "left",
      valign: options.valign || "top",
      breakLine: false,
      fit: "shrink",
      charSpacing: 0,
    };
    this.slide.addText(value, settings);
    this.elements.push({ type: "text", value, x, y, w, h, ...settings });
  }

  image(name, x, y, w, h, options = {}) {
    const imagePath = path.join(ASSET_DIR, `${name}.jpg`);
    this.slide.addImage({ path: imagePath, x, y, w, h });
    if (options.line) {
      this.slide.addShape("rect", {
        x,
        y,
        w,
        h,
        fill: { color: COLORS.white, transparency: 100 },
        line: { color: options.line, width: options.lineWidth || 1 },
      });
    }
    this.elements.push({ type: "image", imagePath, x, y, w, h, line: options.line });
  }

  notes(value) {
    this.slide.addNotes(value);
  }

  async renderPreview(fileName) {
    const width = Math.round(SLIDE_W * PREVIEW_SCALE);
    const height = Math.round(SLIDE_H * PREVIEW_SCALE);
    const svg = [];
    const definitions = [];

    for (const [index, element] of this.elements.entries()) {
      const x = Math.round(element.x * PREVIEW_SCALE);
      const y = Math.round(element.y * PREVIEW_SCALE);
      const w = Math.round(element.w * PREVIEW_SCALE);
      const h = Math.round(element.h * PREVIEW_SCALE);

      if (element.type === "rect") {
        svg.push(`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${element.radius * PREVIEW_SCALE}" fill="#${element.fill}"${element.line ? ` stroke="#${element.line.color}" stroke-width="${element.line.width || 1}"` : ""}/>`);
      }

      if (element.type === "image") {
        const clipId = `clip-${index}`;
        definitions.push(`<clipPath id="${clipId}"><rect x="${x}" y="${y}" width="${w}" height="${h}"/></clipPath>`);
        svg.push(`<image href="${imageData(element.imagePath)}" x="${x}" y="${y}" width="${w}" height="${h}" preserveAspectRatio="xMidYMid slice" clip-path="url(#${clipId})"/>`);
        if (element.line) {
          svg.push(`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="none" stroke="#${element.line}" stroke-width="1"/>`);
        }
      }

      if (element.type === "text") {
        const fontSize = element.fontSize * 1.333;
        const lines = String(element.value).split("\n");
        const anchor = element.align === "center" ? "middle" : element.align === "right" ? "end" : "start";
        const textX = element.align === "center" ? x + w / 2 : element.align === "right" ? x + w : x;
        const lineHeight = fontSize * 1.12;
        const firstY = y + fontSize;
        const tspans = lines.map((line, lineIndex) => `<tspan x="${textX}" dy="${lineIndex === 0 ? 0 : lineHeight}">${xmlEscape(line)}</tspan>`).join("");
        svg.push(`<text x="${textX}" y="${firstY}" text-anchor="${anchor}" font-family="${FONT}" font-size="${fontSize}" font-weight="${element.bold ? 700 : 400}" fill="#${element.color}">${tspans}</text>`);
      }
    }

    const document = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}"><defs>${definitions.join("")}</defs>${svg.join("")}</svg>`;
    await sharp(Buffer.from(document)).png().toFile(path.join(PREVIEW_DIR, fileName));
  }
}

function addEyebrow(builder, value, x = 0.6, y = 0.45, color = COLORS.coral) {
  builder.text(value.toUpperCase(), x, y, 4.5, 0.25, { fontSize: 8, bold: true, color });
}

function addTitle(builder, value, x = 0.6, y = 0.72, w = 7.5, color = COLORS.inkStrong, size = 25) {
  builder.text(value, x, y, w, 0.55, { fontSize: size, bold: true, color });
}

function addPageNumber(builder, value, color = COLORS.muted) {
  builder.text(String(value).padStart(2, "0"), 12.25, 7.08, 0.48, 0.2, { fontSize: 7, bold: true, color, align: "right" });
}

function addCallout(builder, label, value, x, y, w, accent = COLORS.mintDark) {
  builder.rect(x, y, 0.06, 0.78, accent);
  builder.text(label.toUpperCase(), x + 0.2, y, w - 0.2, 0.2, { fontSize: 7, bold: true, color: COLORS.muted });
  builder.text(value, x + 0.2, y + 0.24, w - 0.2, 0.46, { fontSize: 15, bold: true, color: COLORS.inkStrong });
}

function addStatus(builder, number, label, x, y, w, accent) {
  builder.text(number, x, y, w, 0.45, { fontSize: 21, bold: true, color: accent });
  builder.text(label.toUpperCase(), x, y + 0.52, w, 0.25, { fontSize: 7, bold: true, color: COLORS.muted });
}

function addModuleHeader(builder, index, title, purpose, page) {
  builder.text(`ETAPA ${String(index).padStart(2, "0")} DE 05`, 0.62, 0.42, 2.4, 0.25, { fontSize: 9, bold: true, color: COLORS.coral });
  builder.text(title, 0.62, 0.72, 5.6, 0.55, { fontSize: 26, bold: true, color: COLORS.inkStrong });
  builder.text(purpose, 0.62, 1.28, 3.8, 0.88, { fontSize: 15, color: COLORS.inkSoft });
  addPageNumber(builder, page);
}

function addQuestion(builder, value, x, y, w, h = 1.15) {
  builder.rect(x, y, w, h, COLORS.inkStrong);
  builder.text("PERGUNTA QUE A ABA RESPONDE", x + 0.24, y + 0.2, w - 0.48, 0.2, { fontSize: 8, bold: true, color: COLORS.mint });
  builder.text(value, x + 0.24, y + 0.48, w - 0.48, h - 0.6, { fontSize: 16, bold: true, color: COLORS.white });
}

function addStep(builder, number, title, description, x, y, w, accent = COLORS.mintDark) {
  builder.text(String(number).padStart(2, "0"), x, y, 0.5, 0.35, { fontSize: 18, bold: true, color: accent });
  builder.text(title, x + 0.62, y, w - 0.62, 0.32, { fontSize: 14, bold: true, color: COLORS.inkStrong });
  builder.text(description, x + 0.62, y + 0.36, w - 0.62, 0.5, { fontSize: 12, color: COLORS.inkSoft });
}

function addModuleMapItem(builder, number, title, description, x, y, accent) {
  builder.text(String(number).padStart(2, "0"), x, y, 0.65, 0.45, { fontSize: 21, bold: true, color: accent });
  builder.text(title, x + 0.82, y + 0.02, 4.35, 0.34, { fontSize: 16, bold: true, color: COLORS.inkStrong });
  builder.text(description, x + 0.82, y + 0.43, 4.45, 0.55, { fontSize: 12, color: COLORS.inkSoft });
  builder.rect(x + 0.82, y + 1.07, 4.45, 0.012, COLORS.line);
}

async function buildPresentation() {
  const pptx = new PptxGenJS();
  pptx.layout = "LAYOUT_WIDE";
  pptx.author = "TributaLab";
  pptx.company = "TributaLab";
  pptx.subject = "Onboarding do Auditor Fiscal";
  pptx.title = "TributaLab Auditor Fiscal";
  pptx.lang = "pt-BR";
  pptx.theme = {
    headFontFace: FONT,
    bodyFontFace: FONT,
    lang: "pt-BR",
  };

  const builders = [];

  {
    const builder = new SlideBuilder(pptx, COLORS.inkStrong);
    builder.rect(0, 0, 6.55, SLIDE_H, COLORS.inkStrong);
    builder.image("capa", 6.55, 0, 6.783, 7.5);
    builder.rect(6.28, 0, 0.8, 7.5, COLORS.inkStrong);
    builder.text("TL", 0.65, 0.52, 0.55, 0.4, { fontSize: 18, bold: true, color: COLORS.white });
    builder.text("TRIBUTA LAB", 1.25, 0.61, 1.8, 0.25, { fontSize: 9, bold: true, color: COLORS.mint });
    builder.text("TRIBUTALAB\nAUDITOR FISCAL", 0.68, 1.55, 5.1, 1.5, { fontSize: 34, bold: true, color: COLORS.white });
    builder.text("6 abas organizadas em 5 leituras", 0.68, 3.38, 4.9, 0.48, { fontSize: 20, color: COLORS.mint });
    builder.text("Da visão executiva ao lançamento que comprova cada número.", 0.68, 4.35, 4.9, 0.95, { fontSize: 16, color: COLORS.white });
    builder.text("FATURAMENTO · RECEBIMENTOS · FOLHA · DESPESAS", 0.68, 6.55, 4.9, 0.25, { fontSize: 8, bold: true, color: COLORS.gold });
    builder.notes("Este onboarding cobre as cinco leituras que orientam o uso do Auditor Fiscal: receita, caixa, conciliação, déficit da folha e despesas. O foco é saber onde olhar e qual ação tomar em cada etapa.");
    builders.push(builder);
  }

  {
    const builder = new SlideBuilder(pptx);
    addEyebrow(builder, "Visão geral");
    addTitle(builder, "6 abas. 5 leituras que orientam ação.", 0.62, 0.76, 9.8, COLORS.inkStrong, 27);
    builder.text("Cada etapa responde uma pergunta objetiva.", 0.64, 1.38, 7.5, 0.4, { fontSize: 15, color: COLORS.inkSoft });
    addModuleMapItem(builder, 1, "Faturamento", "Quanto foi emitido, retido e convertido em líquido?", 0.7, 2.05, COLORS.mintDark);
    addModuleMapItem(builder, 2, "Contas a Receber", "Quanto do valor lançado entrou realmente no caixa?", 6.72, 2.05, COLORS.coral);
    addModuleMapItem(builder, 3, "Cruzamento", "Quais notas divergem ou existem em apenas uma fonte?", 0.7, 3.52, COLORS.gold);
    addModuleMapItem(builder, 4, "Folha: foco no déficit", "Em quais clientes a folha supera o faturamento?", 6.72, 3.52, COLORS.coral);
    addModuleMapItem(builder, 5, "Dashboard + Explorador", "Onde o gasto pesa e qual lançamento explica o total?", 3.72, 4.99, COLORS.mintDark);
    builder.rect(0, 6.55, 13.333, 0.95, COLORS.inkStrong);
    builder.text("FLUXO RECOMENDADO", 0.72, 6.84, 1.8, 0.2, { fontSize: 8, bold: true, color: COLORS.mint });
    builder.text("visão geral  →  exceção  →  evidência", 2.58, 6.72, 6.0, 0.35, { fontSize: 17, bold: true, color: COLORS.white });
    addPageNumber(builder, 2);
    builder.notes("A apresentação segue cinco perguntas práticas. Faturamento mostra a receita líquida. Contas a Receber mostra o caixa. Cruzamento localiza exceções. Folha prioriza clientes deficitários. Despesas une a visão consolidada ao lançamento detalhado.");
    builders.push(builder);
  }

  {
    const builder = new SlideBuilder(pptx);
    addModuleHeader(builder, 1, "Faturamento", "Entenda a receita emitida, as retenções\ne onde ela está concentrada.", 3);
    addQuestion(builder, "Quanto do faturado\npermanece líquido?", 0.62, 2.12, 3.85, 1.18);
    builder.text("LEIA NESTA ORDEM", 0.62, 3.64, 2.2, 0.22, { fontSize: 9, bold: true, color: COLORS.coral });
    addStep(builder, 1, "Faturado e líquido", "Veja o total emitido, o retido e o valor líquido.", 0.62, 4.02, 3.85, COLORS.mintDark);
    addStep(builder, 2, "Retenções por tributo", "Identifique quais tributos formam a retenção.", 0.62, 5.02, 3.85, COLORS.coral);
    addStep(builder, 3, "Principais tomadores", "Observe onde a receita está mais concentrada.", 0.62, 6.02, 3.85, COLORS.gold);
    builder.image("faturamento_kpis", 5.02, 1.52, 7.7, 1.55, { line: COLORS.line });
    builder.image("faturamento_retencoes", 5.02, 3.3, 3.72, 3.25, { line: COLORS.line });
    builder.image("faturamento_tomadores", 8.94, 3.3, 3.78, 3.25, { line: COLORS.line });
    addPageNumber(builder, 3);
    builder.notes("Na aba Faturamento, a leitura começa no total emitido e chega ao valor líquido. Depois, verificamos quais tributos explicam as retenções e quais tomadores concentram a receita. A saída é uma visão clara da receita líquida e de sua concentração.");
    builders.push(builder);
  }

  {
    const builder = new SlideBuilder(pptx, COLORS.white);
    addModuleHeader(builder, 2, "Contas a Receber", "Acompanhe o que foi lançado,\no que entrou no caixa e o que ficou pendente.", 4);
    addQuestion(builder, "Do valor lançado, quanto\nfoi recebido de verdade?", 0.62, 2.12, 3.85, 1.18);
    builder.text("LEIA NESTA ORDEM", 0.62, 3.64, 2.2, 0.22, { fontSize: 9, bold: true, color: COLORS.coral });
    addStep(builder, 1, "Bruto lançado", "É o ponto de partida das notas selecionadas.", 0.62, 4.02, 3.85, COLORS.mintDark);
    addStep(builder, 2, "Recebido real", "Mostra o valor que efetivamente entrou no caixa.", 0.62, 4.92, 3.85, COLORS.gold);
    addStep(builder, 3, "Pendências", "Contingenciado e saldo sinalizado pedem atenção.", 0.62, 5.82, 3.85, COLORS.coral);
    addStep(builder, 4, "Prioridade", "Use maiores clientes e contingências para agir.", 0.62, 6.65, 3.85, COLORS.inkSoft);
    builder.image("receber_kpis", 4.9, 1.42, 7.84, 1.72, { line: COLORS.line });
    builder.image("receber_clientes", 4.9, 3.38, 5.55, 3.55, { line: COLORS.line });
    builder.image("receber_contingencias", 10.65, 3.38, 2.09, 3.55, { line: COLORS.line });
    addPageNumber(builder, 4);
    builder.notes("Em Contas a Receber, partimos do bruto lançado e verificamos o recebido real. Contingenciado e saldo sinalizado mostram o que exige tratamento. Os rankings ajudam a decidir onde o impacto de caixa é maior.");
    builders.push(builder);
  }

  {
    const builder = new SlideBuilder(pptx);
    addModuleHeader(builder, 3, "Cruzamento", "Configure cada fonte antes de comparar\nfaturamento e recebimentos.", 5);
    addQuestion(builder, "Estou comparando períodos\ne critérios equivalentes?", 0.62, 2.12, 3.85, 1.18);
    builder.text("CADA LADO É INDEPENDENTE", 0.62, 3.65, 3.4, 0.24, { fontSize: 9, bold: true, color: COLORS.coral });
    addStep(builder, 1, "Emissão", "Defina o período dos documentos em cada fonte.", 0.62, 4.03, 3.85, COLORS.mintDark);
    addStep(builder, 2, "Competência", "Escolha a competência de cada lado da comparação.", 0.62, 5.03, 3.85, COLORS.coral);
    addStep(builder, 3, "Tipo de valor", "Compare bruto, líquido ou recebido conforme o objetivo.", 0.62, 6.03, 3.85, COLORS.gold);
    builder.image("cruzamento_filtros", 4.78, 2.08, 7.92, 2.26, { line: COLORS.line });
    builder.rect(4.78, 4.72, 7.92, 1.35, COLORS.paperDeep);
    builder.text("REGRA PRÁTICA", 5.12, 5.0, 1.5, 0.2, { fontSize: 8, bold: true, color: COLORS.coral });
    builder.text("Primeiro alinhe os filtros.\nDepois interprete a diferença.", 5.12, 5.34, 6.8, 0.58, { fontSize: 18, bold: true, color: COLORS.inkStrong });
    addPageNumber(builder, 5);
    builder.notes("O Cruzamento tem dois momentos. Primeiro, configure cada fonte. Emissão, competência e tipo de valor são independentes no lado do faturamento e no lado dos recebimentos. Só depois de alinhar o objetivo da comparação devemos interpretar o resultado.");
    builders.push(builder);
  }

  {
    const builder = new SlideBuilder(pptx, COLORS.white);
    addModuleHeader(builder, 3, "Cruzamento", "Leia o resultado como um mapa\nde exceções entre as duas fontes.", 6);
    addQuestion(builder, "Onde faturamento e\nrecebimentos não fecham?", 0.62, 2.12, 3.35, 1.18);
    addStep(builder, 1, "Conciliada", "A nota existe nas duas fontes\ne os valores coincidem.", 0.62, 3.65, 3.35, COLORS.mintDark);
    addStep(builder, 2, "Divergência", "A nota existe nas duas fontes,\nmas os valores diferem.", 0.62, 4.55, 3.35, COLORS.coral);
    addStep(builder, 3, "Ausente em recebimentos", "Foi faturada, mas não apareceu\nna entrada selecionada.", 0.62, 5.45, 3.35, COLORS.gold);
    addStep(builder, 4, "Ausente em faturamento", "Entrou no recebimento, mas não está\nna emissão selecionada.", 0.62, 6.35, 3.35, COLORS.inkSoft);
    builder.image("cruzamento_resultado", 4.35, 1.48, 8.35, 3.56, { line: COLORS.line });
    builder.image("cruzamento_tabela", 4.35, 5.28, 8.35, 1.62, { line: COLORS.line });
    addPageNumber(builder, 6);
    builder.notes("O resultado separa quatro situações. Conciliada significa que a nota existe nas duas fontes e fecha em valor. Divergência significa que existe nos dois lados, mas não fecha. Os ausentes mostram documentos presentes em apenas uma fonte. A tabela permite investigar nota a nota.");
    builders.push(builder);
  }

  {
    const builder = new SlideBuilder(pptx);
    addModuleHeader(builder, 4, "Folha: o déficit é o alerta", "Encontre clientes cuja folha líquida\né maior que o faturamento da competência.", 7);
    builder.rect(0.62, 2.08, 3.35, 1.55, COLORS.coral);
    builder.text("215", 0.9, 2.35, 1.35, 0.62, { fontSize: 34, bold: true, color: COLORS.white });
    builder.text("COMPETÊNCIAS\nCOM DÉFICIT", 2.08, 2.4, 1.55, 0.62, { fontSize: 12, bold: true, color: COLORS.white });
    builder.text("O QUE SIGNIFICA", 0.62, 4.02, 2.2, 0.22, { fontSize: 9, bold: true, color: COLORS.coral });
    builder.text("Folha líquida > faturamento", 0.62, 4.38, 3.35, 0.36, { fontSize: 17, bold: true, color: COLORS.inkStrong });
    builder.text("A diferença negativa indica que a receita\ndaquele cliente não cobre o custo da folha\nna competência.", 0.62, 4.82, 3.35, 0.92, { fontSize: 13, color: COLORS.inkSoft });
    addStep(builder, 1, "Filtre “Déficit”", "Isole somente as competências que exigem revisão.", 0.62, 5.92, 3.35, COLORS.coral);
    addStep(builder, 2, "Abra o cliente", "Compare folha líquida, faturamento e diferença.", 0.62, 6.7, 3.35, COLORS.gold);
    builder.image("folha_resumo", 4.55, 1.45, 8.18, 2.72, { line: COLORS.line });
    builder.image("folha_tabela", 4.55, 4.42, 8.18, 2.6, { line: COLORS.line });
    addPageNumber(builder, 7);
    builder.notes("Na Folha, o principal alerta é o déficit. Ele ocorre quando a folha líquida do cliente é maior que o faturamento da mesma competência. Existem 215 competências nessa situação. A ação é filtrar Déficit e abrir a linha do cliente para comparar folha líquida, faturamento e diferença. Vencimentos e descontos apenas formam a folha líquida usada nessa conta.");
    builders.push(builder);
  }

  {
    const builder = new SlideBuilder(pptx, COLORS.white);
    addModuleHeader(builder, 5, "Despesas: do total ao lançamento", "Use o Dashboard para localizar o gasto\ne o Explorador para entender sua composição.", 8);
    addQuestion(builder, "Onde está o gasto e qual\nlançamento explica o valor?", 0.62, 2.12, 3.35, 1.18);
    addStep(builder, 1, "Localize no Dashboard", "Veja o total pago e as categorias com maior peso.", 0.62, 3.65, 3.35, COLORS.mintDark);
    addStep(builder, 2, "Leve o recorte ao Explorador", "Filtre fornecedor ou funcionário e a categoria.", 0.62, 4.65, 3.35, COLORS.coral);
    addStep(builder, 3, "Confira o lançamento", "Abra favorecido, descrição, competência e valor.", 0.62, 5.65, 3.35, COLORS.gold);
    builder.rect(0.62, 6.64, 3.35, 0.48, COLORS.inkStrong);
    builder.text("TOTAL  →  FILTRO  →  LANÇAMENTO", 0.79, 6.78, 3.0, 0.2, { fontSize: 9, bold: true, color: COLORS.white, align: "center" });
    builder.image("despesas_resumo", 4.4, 1.45, 8.3, 1.55, { line: COLORS.line });
    builder.image("explorador_filtros", 4.4, 3.23, 8.3, 1.55, { line: COLORS.line });
    builder.image("explorador_tabela", 4.4, 5.0, 8.3, 1.92, { line: COLORS.line });
    addPageNumber(builder, 8);
    builder.notes("Despesas funciona como um único fluxo. No Dashboard, localizamos o total pago e a categoria que mais pesa. Depois, no Explorador, aplicamos o filtro de fornecedor ou funcionário e a categoria. Por fim, abrimos o lançamento para conferir favorecido, descrição, competência e valor.");
    builders.push(builder);
  }

  await Promise.all(builders.map((builder, index) => builder.renderPreview(`slide_${String(index + 1).padStart(2, "0")}.png`)));
  await pptx.writeFile({ fileName: OUTPUT_PATH });
  console.log(`PowerPoint gerado: ${OUTPUT_PATH}`);
  console.log(`Prévias geradas: ${PREVIEW_DIR}`);
}

async function main() {
  fs.mkdirSync(PREVIEW_DIR, { recursive: true });
  for (const fileName of fs.readdirSync(PREVIEW_DIR)) {
    if (/^slide_\d+\.png$/.test(fileName)) {
      fs.unlinkSync(path.join(PREVIEW_DIR, fileName));
    }
  }
  await prepareSourceOverviews();
  await prepareCrops();
  await buildPresentation();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});