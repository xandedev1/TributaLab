# DECISAO 003 - Casos internos e simulacoes

## Contexto

A Etapa 003 precisava transformar o TributaLab em uma ferramenta mais operacional para validacao interna, sem criar cadastro comercial completo de empresas/clientes e sem declarar o sistema pronto para uso real.

As simulacoes ja eram auditaveis desde a Etapa 002, mas faltava uma forma simples de agrupar estudos e revisoes internas.

## Decisoes

- Criar `CaseFile` como entidade simples de agrupamento interno.
- Manter `Simulation belongs_to :case_file, optional: true`.
- Manter `CaseFile has_many :simulations` com `dependent: :nullify`, para nao apagar simulacoes auditaveis ao remover/desvincular um caso no futuro.
- Nao criar cadastro completo de cliente, empresa, conta, usuario, permissao ou multi-tenant nesta etapa.
- Nao exigir dados sensiveis em `CaseFile`.
- Criar seed de caso interno de validacao para organizar simulacoes guiadas do modulo imobiliario.

## Campos de CaseFile

- `name`
- `description`
- `status`
- `reference_code`
- `notes`

## Por que CaseFile nao e cadastro de cliente

`CaseFile` existe apenas para organizar simulacoes internas por estudo, roteiro ou validacao. Ele nao representa empresa real, contrato comercial, conta de cliente, grupo economico, usuario final ou ambiente isolado.

Por isso, ele nao possui CNPJ, razao social, responsaveis, endereco, documentos, permissoes, participantes, anexos ou dados sensiveis obrigatorios.

## Relacao com Simulation

Uma simulacao pode estar vinculada a um caso interno, mas isso e opcional.

Essa opcionalidade preserva o fluxo rapido de simulacao e permite que estudos mais organizados agrupem resultados quando necessario.

## Limites para uso com empresas reais

Antes de usar o TributaLab com empresas reais, ainda sera necessario implementar pelo menos:

- cadastro formal de cliente/empresa;
- usuarios e permissoes;
- controle de acesso;
- governanca de parametros e versoes de regras;
- validacao juridica das regras pendentes;
- relatorios exportaveis;
- trilha de auditoria mais formal;
- termos de uso e disclaimer.

## Consequencias

A Etapa 003 ganha uma camada operacional suficiente para validacao interna guiada, mantendo separacao clara entre caso interno de estudo e cadastro real de cliente.