# Brief da Landing Page — Real Audit Tech

> Documento pronto para entregar a um designer/IA (ex.: Claude) construir a landing page de **realaudittech.com**.
> Referência de estrutura/estilo: `realprev.com` (dark, profissional, hero com métricas, features numeradas, tabela/seção de credibilidade, CTA de demonstração por WhatsApp + link de login).

---

## 0. Marca

- **Nome do produto:** Real Audit Tech
- **Assinatura:** Tecnologia Tributária
- **Logo:** `logo com nome` (horizontal, para o topo) e `logo sem nome` (o monograma RAT, para favicon/ícone). Arquivos em `app/assets/images/real-audit-tech-logo.png` e `real-audit-tech-mark.png`.
- **Paleta:** verde-escuro petróleo de fundo (do logo, ~`#16302B`), texto branco, detalhe/realce em coral/laranja queimado (`#D66E54`) ou verde claro. Visual dark, sério, "mesa de auditoria", sem cara de template.
- **Tom:** comercial e direto, mas técnico e confiável. Nada de exagero de marketing; fala de números, prova e dinheiro.

### Slogan (principal)
> **Do faturamento ao dinheiro a cobrar — nota a nota.**

Alternativas:
- "A auditoria fiscal que mostra, nota a nota, o que você tem a receber."
- "Auditoria fiscal multiempresa. Com prova, não com achismo."

---

## 1. NAV (topo fixo)
`Logo Real Audit Tech` · **O que faz** (#sistema) · **Módulos** (#modulos) · **Segurança** (#seguranca) · **Contato** (#contato) · **Entrar** (→ /login) · **Solicitar demonstração** (botão destacado → WhatsApp)

---

## 2. HERO
- **Kicker:** `AUDITORIA FISCAL · MULTIEMPRESA`
- **Headline:** **Real Audit Tech — auditoria fiscal, da planilha ao dinheiro a cobrar.**
- **Subheadline:** O Real Audit Tech cruza faturamento, contas a receber, folha e obrigações fiscais de cada empresa e mostra, **nota a nota**, o que foi faturado e não entrou no caixa — e onde os valores não fecham.
- **CTAs:** `Solicitar demonstração` (WhatsApp) · `Já tenho conta — entrar` (/login)
- **3 badges de métrica** (destaque visual, estilo Real Prev):
  - `NOTA A NOTA` — cruzamento por **código do cliente + número da NF**
  - `RASTREÁVEL` — cada número com **memória de cálculo e planilha de origem**
  - `MULTIEMPRESA` — cada empresa **vê só os dados dela**

---

## 3. SISTEMA — "O que o Real Audit Tech faz" (features numeradas 01–04)

**01 · Cruzamento Faturamento × Contas a receber**
Bate cada nota emitida contra o contas a receber pela chave *código do cliente + NF*. Em segundos você vê o que **casou**, o que **divergiu em valor** e o que foi **faturado e nunca recebido** — o dinheiro a cobrar.

**02 · Auditoria de folha e custo de pessoal**
Folha de pagamento, recomposição de **encargos INSS e FGTS** (mensal + 13º) e **extrato de conta vinculada** por contrato. Do bruto ao líquido ajustado, com cada rubrica rastreada.

**03 · Auditoria fiscal de receita**
Cruzamento **EFD × Razão**, comparativo **EFD × ECF** e **devoluções** — para conferir a receita declarada contra a contábil, mês a mês.

**04 · Rastreabilidade total**
Todo valor abre a **memória de cálculo** (como o número foi formado) e a **fonte original** (a linha exata da planilha). Auditoria com prova.

---

## 4. MÓDULOS — "Tudo em um só painel" (grid de chips/cards)
Faturamento · Contas a receber · Faturamento × Contas a receber · Extrato conta vinculada · Despesas · Folha · Encargos (INSS/FGTS) · Lotações tributárias · Cruzamento EFD × Razão · Comparativo EFD × ECF · Devoluções · Relatórios gerados

---

## 5. SEGURANÇA / MULTIEMPRESA — "Cada empresa, só o que é dela"
Isolamento total por empresa: dados, cruzamentos e relatórios são segmentados por CNPJ. Uma empresa nunca enxerga a outra. Onboarding de nova empresa em minutos, sem misturar nada. (Base PostgreSQL com escopo por empresa.)

---

## 6. COMO FUNCIONA (3 passos — opcional, estilo timeline)
1. **Suba os arquivos** da empresa (faturamento, contas a receber, folha, EFD...).
2. **O sistema cruza** tudo pela chave certa e monta os painéis.
3. **Você audita** nota a nota: o que cobrar, o que diverge, com memória e prova.

---

## 7. CONTATO — "Veja o Real Audit Tech em ação"
Agende uma demonstração para o seu escritório ou departamento fiscal. Atendemos por WhatsApp ou e-mail.
- CTA primário: `Solicitar demonstração no WhatsApp` → **[CONFIRMAR NÚMERO]** (provável MCAP: `+55 11 96189-4772`)
- E-mail: **[CONFIRMAR]** (provável: `contato@mcap.com.br`)

---

## 8. FOOTER
- **Tagline:** Auditoria fiscal multiempresa — do faturamento ao dinheiro a cobrar, nota a nota.
- Links: O que faz · Módulos · Segurança · Contato · Entrar
- `© 2026 Real Audit Tech · Tecnologia Tributária. Todos os direitos reservados.`

---

## 9. Requisitos técnicos da LP (para o designer)
- **Estática e leve** (HTML/CSS, sem framework pesado), responsiva, dark por padrão.
- Servida na raiz `realaudittech.com`; o botão **Entrar** aponta para `/login` (app Rails já existente).
- SEO básico: `<title>Real Audit Tech — Auditoria Fiscal Multiempresa</title>`, meta description com o subheadline, favicon = `real-audit-tech-mark.png`.
- Sem emojis; tipografia limpa; usar o verde-escuro do logo como fundo.

## 10. A confirmar com o cliente
1. WhatsApp e e-mail oficiais (é o mesmo da MCAP/Real Prev?).
2. Se a raiz `/` deve ser a LP com botão Entrar (recomendado) — hoje `/` redireciona direto para `/login`.
