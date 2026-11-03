# AGENTS.md

Repositório de reprodução da análise ACPNL do TCC (`docs/TCC_v15_final.md`, cap. 5.3).
Não é um pacote de software: não há build, testes, lint nem git. A "verificação" é
batir números com tabelas do TCC.

Etapas concluídas:
- **ACPNL** — 4 rounds (nominal 5d, ordinal 5d, nominal 4d, nominal 5d splines)
- **ACP logística** — 2 rounds (MM e relaxamento convexo, 5 dimensões) +
  relatório de análise em HTML

## Comandos

Rodar qualquer script R **sempre via** `rrun.ps1` (Windows) ou `rrun.sh` (Linux,
incl. SteamOS) — ambos usam o R 4.0.5 + a lib travada do respectivo SO:

```powershell
# Windows
.\rrun.ps1 scripts\acpnl_fit_nom_5d.r        # idem para os outros 3 scripts de fit ACPNL
.\rrun.ps1 scripts\acpl_fit_5d_mm.r          # ACP logística, algoritmo MM
.\rrun.ps1 scripts\acpl_fit_5d_convex.r      # ACP logística, relaxamento convexo
.\rrun.ps1 scripts\acpl_relatorio.r          # relatório de análise (HTML)
```

```bash
# Linux / SteamOS (bash/sh)
./rrun.sh scripts/acpnl_fit_nom_5d.r         # idem para os outros scripts
./rrun.sh scripts/acpl_relatorio.r
```

- Em contexto não-interativo (Windows): `powershell -ExecutionPolicy Bypass -File .\rrun.ps1 <script>`
- Os executores fazem `Set-Location`/`cd` na raiz — os scripts usam caminhos
  relativos (`dados/`, `fits/`, `resultados/`) e dependem disso.
- O projeto fixa o **R 4.0.5**: o Gifi 0.3-9 é binário pré-compilado da era
  pré-UCRT e não carrega no R ≥ 4.2. A lib de pacotes é resolvida por
  `scripts/get_data.r` (`.libPaths` relativo ao script) — **por SO**:
  Windows `libs/Rlib_r40` (binários), Linux `libs/Rlib_r40_linux` (fonte, mesma
  versões); a escolha é automática em `get_data.r` via `.Platform$OS.type`.
- Os executores **não** definem `R_LIBS_USER`; só o `get_data.r` resolve a lib.
  Rscript direto com scripts que não `source()`am o `get_data.r` precisa de
  `.libPaths` manual.
- **Linux/SteamOS**: o R 4.0.5 em si vive no repo (`libs/mamba_r40`, conda env
  via micromamba, com gcc/gfortran do conda-forge), criado uma única vez por
  `./setup/setup_r40_linux.sh` (sem root). Detalhes da lib Linux em
  `setup/install_lib_r40_linux.r`.

## Como o pipeline funciona

- `scripts/get_data.r` é o pré-processamento comum (fonte única): leitura de
  `dados/olist.csv`, filtros, binning OneR, rename ATS/ATD/... — e define
  `figuras()` (grava os 3 plots). É `source()`ado por cada script de fit.
- Um script por rodada; nome do script = nome do fit:
  - ACPNL: `acpnl_fit_nom_5d.r` → `fits/acpnl_fit_nom_5d.rds` (+ 3 plots
    `resultados/plots/acpnl_fig_nom5d_{scree,loadplot,transplot}.png`)
  - ACP logística: `acpl_fit_5d_mm.r` / `acpl_fit_5d_convex.r` →
    `fits/acpl_fit_5d_{mm,convex}.rds` (+ 3 plots cada um
    `resultados/plots/acpl_fig_{mm5d,cvx5d}_{scree,loadplot,transplot}.png`)
- O prefixo `acpnl_` é **por técnica** (ACPNL); o prefixo `acpl_` é para a
  ACP logística. Nunca misturar prefixos entre técnicas.
- `scripts/get_data.r` é o pré-processamento comum da ACPNL; `scripts/acpl_prep.r`
  é o pré-processamento comum da ACP logística (reaproveita `get_data.r` e
  binariza: RS boa/ruim > 3, dummies de bins OneR com referência no 1º nível,
  PT em dummies com referência boleto). Define helpers `acpl_scree` /
  `acpl_loadplot` / `acpl_transplot`.
- O relatório da ACP logística é gerado por `scripts/acpl_relatorio.r`
  (HTML auto-contido com tabelas extraídas dos fits salvos + as 6 figuras).
  É salvo em `resultados/relatorio_acp_logistica.html` para revisão manual;
  não é um artefato de reprodução numérica.
- Sumários vão só para o console. **Não criar** arquivos `.txt` em `resultados/`
  (decisão do dono do projeto).

## Verificação de reprodução (o "teste" deste repo)

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

## Armadilhas

- **Versão do Gifi importa**: 0.3-9 (2019) reproduz; 1.0-0 (2025) alterou o
  `princals` e os números mudam. O `libs/Rlib_r40` fixa o Gifi 0.3-9.
- `libs/Rlib_r40` também tem o `logisticPCA` 0.2 (Landgraf) para a rodada de
  ACP logística. Para reinstalar: o índice PACKAGES do cran-archive **não**
  lista o pacote — baixar o zip direto
  (`bin/windows/contrib/4.0/logisticPCA_0.2.zip`) e usar
  `install.packages(<zip>, repos=NULL)`.
- PowerShell `Set-Content -Encoding UTF8` grava BOM e o R 4.0.5 quebra com
  `unexpected input`. Se reescrever scripts .r por shell, gravar UTF-8 **sem BOM**.
- `libs/` é grande e é parte do ambiente. Se apagada, reinstalar com binários de
  arquivo do CRAN (receita no README): R 4.0.5 + `https://cran-archive.r-project.org`.
  No Linux, `./setup/setup_r40_linux.sh` recria R (`libs/mamba_r40`) e a lib
  (`libs/Rlib_r40_linux`) do zero, de forma idempotente.
- **Compilação da lib no Linux**: o gcc moderno (≥ 15) usa C23 como default e
  quebra fontes da era 2020 (`mgcv` usa `true` como nome de variável; `survival`
  tem protótipos K&R). O `setup_r40_linux.sh` fixa `-std=gnu17` para toda a
  compilação via `libs/Makevars_r40_linux` + `R_MAKEVARS_USER`.
- **O Gifi 0.3-9 não está no Archive do CRAN** — no Linux ele vem do snapshot do
  Posit Package Manager do dia da construção da lib Windows (`2022-04-21`),
  fixado em `setup/install_lib_r40_linux.r`. O snapshot também garante todas
  as demais versões travadas; o instalador confere a versão de cada tarball
  antes de compilar.
- O `r-base` do conda **não** traz os pacotes "recommended" (`MASS`, `Matrix`,
  `mgcv`...): o `ggplot2` (Imports do `logisticPCA`) exige `MASS`/`mgcv`, e `mgcv`
  exige `Matrix`/`nlme` — o instalador os compila junto na lib do projeto.
  `survival`/`lattice` não são necessários (apenas Suggests de mgcv/ggplot2).
