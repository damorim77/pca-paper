# Artigo ACP não linear (ACPNL + ACP Logística)

Repositório de código e dados do artigo de **Análise de Componentes Principais: Uma visão extendida da técnica clássica**.

## Técnicas implementadas

| Técnica | Rodadas | Scripts | Saída em `fits/` |
|---------|---------|---------|------------------|
| **ACPNL** (Gifi, `princals`) | 4 | `acpnl_fit_nom_5d.r`, `acpnl_fit_ord_5d.r`, `acpnl_fit_nom_4d.r`, `acpnl_fit_nom_5d_splines.r` | `acpnl_fit_*.rds` |
| **ACP Logística** (`logisticPCA`) | 2 | `acpl_fit_5d_mm.r`, `acpl_fit_5d_convex.r` | `acpl_fit_5d_{mm,convex}.rds` |
| Relatório (HTML) | 1 | `acpl_relatorio.r` | `resultados/relatorio_acp_logistica.html` |

Cada rodada de fit grava ainda 3 figuras (`scree`, `loadplot`, `transplot`) em
`resultados/plots/`.

## Estrutura do repositório

```
pca-paper/
├── dados/
│   └── olist.csv                 # base original (abril/2018, 6.229 registros, 26 colunas)
├── docs/
│   └── TCC_v15_final.md          # texto do TCC (origem da análise ACPNL, cap. 5.3)
├── scripts/
│   ├── get_data.r                # pré-processamento comum da ACPNL + figuras()
│   ├── acpl_prep.r               # pré-processamento da ACP logística (binarização)
│   ├── acpnl_fit_nom_5d.r        # Rodada 1: nominal, 5 dim
│   ├── acpnl_fit_ord_5d.r        # Rodada 2: ordinal (ATD,ODO,SDO,RS,TPV), 5 dim
│   ├── acpnl_fit_nom_4d.r        # Rodada 3: nominal, 4 dim
│   ├── acpnl_fit_nom_5d_splines.r # Rodada 4: nominal, 5 dim + splines
│   ├── acpl_fit_5d_mm.r          # ACP logística, algoritmo MM, 5 componentes
│   ├── acpl_fit_5d_convex.r      # ACP logística, relaxamento convexo, 5 componentes
│   └── acpl_relatorio.r          # relatório HTML (tabelas + 6 figuras)
├── resultados/
│   ├── plots/                    # acpnl_fig_* e acpl_fig_* (scree, loadplot, transplot)
│   └── relatorio_acp_logistica.html
├── fits/                         # objetos salvos (*.rds), um por script de fit
├── libs/
│   └── Rlib_r40/                 # pacotes p/ R 4.0.5 (Gifi 0.3-9, logisticPCA 0.2)
├── AGENTS.md                     # instruções detalhadas para agentes / fluxo de trabalho
├── README.md                     # este arquivo
└── rrun.ps1                      # executor (escolhe Rscript + lib pela versão)
```

O prefixo `acpnl_` identifica a técnica **ACPNL**; o prefixo `acpl_` identifica a
**ACP Logística**. Nunca misturar prefixos entre técnicas.

## Pré-requisitos e ambiente

O projeto é executado com **R 4.0.5** e a biblioteca travada em
`libs/Rlib_r40`:

- **Gifi 0.3-9** (2019) — a única versão que reproduz os números do TCC; o Gifi
  1.0-0 (2025) alterou o `princals` e os números mudam.
- **logisticPCA 0.2** (Landgraf) — para as rodadas de ACP Logística.

Não é um pacote de software: não há build, testes, lint nem git. A verificação é
bater os números com as tabelas do TCC / do artigo.

## Como rodar

Rodar qualquer script R **sempre via** `rrun.ps1` (usa o R 4.0.5 + a lib
`libs/Rlib_r40`):

```powershell
# ACPNL — 4 rodadas
.\rrun.ps1 scripts\acpnl_fit_nom_5d.r
.\rrun.ps1 scripts\acpnl_fit_ord_5d.r
.\rrun.ps1 scripts\acpnl_fit_nom_4d.r
.\rrun.ps1 scripts\acpnl_fit_nom_5d_splines.r

# ACP Logística — 2 rodadas + relatório HTML
.\rrun.ps1 scripts\acpl_fit_5d_mm.r
.\rrun.ps1 scripts\acpl_fit_5d_convex.r
.\rrun.ps1 scripts\acpl_relatorio.r
```

O `rrun.ps1` faz `Set-Location` na raiz do projeto — os scripts usam caminhos
relativos (`dados/`, `fits/`, `resultados/`) e dependem disso.

Caso a política de execução bloqueie o PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\rrun.ps1 scripts\acpnl_fit_nom_5d.r
```

## Verificação de reprodução

Rodada por rodada, os autovalores do `summary(fit)` devem ser exatamente:

1. Nominal, 5 dim: `1.9307 1.3416 1.2059 0.7937 0.6517`
2. Ordinal (ATD,ODO,SDO,RS,TPV), 5 dim: `1.9339 1.3416 1.2037 0.7938 0.6505`
3. Nominal, 4 dim: `1.9330 1.3410 1.1982 0.8094`
4. Nominal, 5 dim + splines: `1.9197 1.3175 1.1844 0.8180 0.6589`

Divergências conhecidas e aceitas (não "corrigir"):
- Componentes 6–7 do scree (não retidas) diferem em ~0,01 do TCC.
- Tabelas de figura do TCC são transcrições aproximadas dos gráficos; comparar
  padrões (sinais/ordem), não valores absolutos de transplot.
- Apêndice B do TCC vem de outra execução anterior (não reproduzível).

## Armadilhas importantes

- **Versão do Gifi importa**: 0.3-9 (2019) reproduz; 1.0-0 (2025) alterou o
  `princals` e os números mudam. O `libs/Rlib_r40` fixa o Gifi 0.3-9.
- `libs/Rlib_r40` também tem o `logisticPCA` 0.2 (Landgraf) para a rodada de
  ACP Logística. Para reinstalar: o índice PACKAGES do cran-archive **não**
  lista o pacote — baixar o zip direto
  (`bin/windows/contrib/4.0/logisticPCA_0.2.zip`) e usar
  `install.packages(<zip>, repos=NULL)`.
- PowerShell `Set-Content -Encoding UTF8` grava BOM e o R 4.0.5 quebra com
  `unexpected input`. Se reescrever scripts `.r` por shell, gravar UTF-8 **sem
  BOM**.
- `libs/` é grande e é parte do ambiente. Se apagada, reinstalar com binários de
  arquivo do CRAN (receita no AGENTS.md): R 4.0.5 +
  `https://cran-archive.r-project.org`.

## Citação

Quando o artigo for publicado, cite aqui com o DOI/link definitivo. Até lá:

> Repositório de código e dados do artigo de PCA (ACPNL + ACP Logística) sobre
> o conjunto Olist. Análise originada da reprodução do TCC
> (`docs/TCC_v15_final.md`, cap. 5.3).

## Licença

Não há licença de software: o repositório serve como material de apoio à
reprodução dos resultados do artigo.
