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
│   ├── get_data.r                  # pré-processamento comum da ACPNL + figuras()
│   ├── acpl_prep.r                 # pré-processamento da ACP logística (binarização)
│   ├── acpnl_fit_nom_5d.r          # Rodada 1: nominal, 5 dim
│   ├── acpnl_fit_ord_5d.r          # Rodada 2: ordinal (ATD,ODO,SDO,RS,TPV), 5 dim
│   ├── acpnl_fit_nom_4d.r          # Rodada 3: nominal, 4 dim
│   ├── acpnl_fit_nom_5d_splines.r # Rodada 4: nominal, 5 dim + splines
│   ├── acpl_fit_5d_mm.r            # ACP logística, algoritmo MM, 5 componentes
│   ├── acpl_fit_5d_convex.r        # ACP logística, relaxamento convexo, 5 componentes
│   ├── acpl_relatorio.r            # relatório HTML (tabelas + 6 figuras)
├── setup/                           # montagem do ambiente Linux (fora do pipeline de análise)
│   ├── setup_r40_linux.sh           #   monta R 4.0.5 + lib no repositório
│   └── install_lib_r40_linux.r     #   compila a lib em fonte, versões travadas
├── resultados/
│   ├── plots/                    # acpnl_fig_* e acpl_fig_* (scree, loadplot, transplot)
│   └── relatorio_acp_logistica.html
├── fits/                         # objetos salvos (*.rds), um por script de fit
├── libs/
│   ├── Rlib_r40/                   # pacotes p/ R 4.0.5 (binários Windows)
│   ├── Rlib_r40_linux/             # pacotes p/ R 4.0.5 (fonte, Linux; gitignored)
│   └── mamba_r40/                  # R 4.0.5 do conda (Linux; gitignored)
├── AGENTS.md                     # instruções detalhadas para agentes / fluxo de trabalho
├── README.md                     # este arquivo
├── rrun.ps1                      # executor (Windows)
└── rrun.sh                       # executor (Linux / SteamOS)
```

O prefixo `acpnl_` identifica a técnica **ACPNL**; o prefixo `acpl_` identifica a
**ACP Logística**. Nunca misturar prefixos entre técnicas.

## Pré-requisitos e ambiente

O projeto é executado com **R 4.0.5** e a biblioteca travada nos pacotes:

- **Gifi 0.3-9** (2019) — a única versão que reproduz os números do TCC; o Gifi
  1.0-0 (2025) alterou o `princals` e os números mudam.
- **logisticPCA 0.2** (Landgraf) — para as rodadas de ACP Logística.

| SO | Executor | Lib de pacotes | Origem |
|----|----------|----------------|--------|
| Windows | `rrun.ps1` | `libs/Rlib_r40/` (binários Windows) | CRAN Archive (binários), instalada em 2022-04-21 |
| Linux (incl. SteamOS) | `rrun.sh` | `libs/Rlib_r40_linux/` (em fonte) | CRAN Archive + snapshot Posit do mesmo dia; montada por `setup/setup_r40_linux.sh` |

No Linux o R 4.0.5 também vive **dentro do repositório** (`libs/mamba_r40`, conda
env via micromamba — sem root, sem instalador de sistema). A lib Linux compila
em fonte exatamente as mesmas versões travadas da lib Windows; a verificação de
reprodução (autovalores abaixo) vale para os dois SOs.

Não é um pacote de software: não há build, testes, lint nem git. A verificação é
bater os números com as tabelas do TCC / do artigo.

### Ambiente Linux/SteamOS: `setup/setup_r40_linux.sh`

O instalador do ambiente Linux. Rode **uma única vez** (e de novo apenas se
apagar `libs/`, ou para montar o repo em outra máquina) — instalado o ambiente,
o dia a dia é só `./rrun.sh <script>`; o setup não entra no fluxo de execução.
Idempotente, sem root, ~1,5 GB dentro do repositório:

1. **micromamba** (`libs/bin/micromamba`) — conda em binário estático; não
   instalar nada no sistema;
2. **R do projeto** (`libs/mamba_r40`) — env conda com exatamente R 4.0.5 +
   gcc/gfortran (na SteamOS o sistema não permite instalar R);
3. **flags de compilação** (`libs/Makevars_r40_linux`, `-std=gnu17`) — o gcc
   moderno (C23) quebra fontes da era 2020 (detalhes no AGENTS.md);
4. **lib de pacotes** (`libs/Rlib_r40_linux`) — via `setup/install_lib_r40_linux.r`:
   baixa (CRAN Archive + snapshot Posit 2022-04-21, onde está o Gifi 0.3-9) e
   compila em fonte as versões exatas da lib Windows, conferindo cada tarball,
   e termina com teste de carregamento de todos os pacotes.

Reiniciar a SteamOS não afeta nada: os passos 1–4 moram no `/home/deck`
(persistente), fora da partição do sistema que atualização de sistema substitui.

## Como rodar

Rodar qualquer script R **sempre via** `rrun.ps1` (Windows) ou `rrun.sh` (Linux)
— ambos usam o R 4.0.5 + a lib travada do respectivo SO:

```powershell
# Windows
.\rrun.ps1 scripts\acpnl_fit_nom_5d.r       # ACPNL — rodada 1 (nominal, 5 dim)
```

```bash
# Linux / SteamOS — prepare o ambiente uma única vez (ver seção abaixo)
./rrun.sh scripts/acpnl_fit_nom_5d.r        # ACPNL — rodada 1 (nominal, 5 dim)
```

Rodadas (troque o script nas linhas acima):

| Grupo | Script |
|-------|--------|
| ACPNL — rodada 1: nominal, 5 dim | `acpnl_fit_nom_5d.r` |
| ACPNL — rodada 2: ordinal (ATD,ODO,SDO,RS,TPV), 5 dim | `acpnl_fit_ord_5d.r` |
| ACPNL — rodada 3: nominal, 4 dim | `acpnl_fit_nom_4d.r` |
| ACPNL — rodada 4: nominal, 5 dim + splines | `acpnl_fit_nom_5d_splines.r` |
| ACP Logística — algoritmo MM, 5 dim | `acpl_fit_5d_mm.r` |
| ACP Logística — relaxamento convexo, 5 dim | `acpl_fit_5d_convex.r` |
| Relatório HTML (ACP Logística) | `acpl_relatorio.r` |

Os executores fazem `cd`/`Set-Location` na raiz do projeto — os scripts usam
caminhos relativos (`dados/`, `fits/`, `resultados/`) e dependem disso.

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
- **No Linux** a lib equivalente é `libs/Rlib_r40_linux/` (fonte, mesmas versões),
  reconstruída com `./setup/setup_r40_linux.sh`. Detalhes: o `r-base` do conda
  **não** traz os "recommended" (`MASS`, `Matrix`, `mgcv`...), que o `ggplot2`
  (Imports do `logisticPCA`) exige — o instalador os compila junto. O **Gifi
  0.3-9 não está no Archive do CRAN**; ele vem do snapshot do Posit Package
  Manager do dia da construção da lib Windows (`2022-04-21`), que também
  garante todas as outras versões travadas.

## Citação

Quando o artigo for publicado, cite aqui com o DOI/link definitivo. Até lá:

> Repositório de código e dados do artigo de PCA (ACPNL + ACP Logística) sobre
> o conjunto Olist. Análise originada da reprodução do TCC
> (`docs/TCC_v15_final.md`, cap. 5.3).

## Licença

Não há licença de software: o repositório serve como material de apoio à
reprodução dos resultados do artigo.
