# Reprodução da ACPNL do TCC

Projeto de reprodução da análise de **Análise de Componentes Principais Não-Linear
(ACPNL)** do TCC (`docs/TCC_v15_final.md`), capítulo 5.3, usando o R *package* **Gifi**
(versão 0.3-9, a vigente em 2020, data da citação no trabalho).

## Estrutura

```
pca-paper/
├── dados/
│   └── olist.csv                 # base original (abril/2018, 6.229 registros, 26 colunas)
├── docs/
│   └── TCC_v15_final.md          # texto do TCC
├── scripts/
│   ├── get_data.r                # preparação da base (comum aos 4 fits) + função figuras()
│   ├── acpnl_fit_nom_5d.r        # Rodada 1: nominal, 5 dim (Tabela 4)
│   ├── acpnl_fit_ord_5d.r        # Rodada 2: ordinal em ATD/ODO/SDO/RS/TPV, 5 dim (Tabela 6)
│   ├── acpnl_fit_nom_4d.r        # Rodada 3: nominal, 4 dim (Tabela 8)
│   └── acpnl_fit_nom_5d_splines.r # Rodada 4: nominal, 5 dim, splines (Tabela 10)
├── resultados/
│   └── plots/                    # acpnl_fig_<id>_<scree|loadplot|transplot>.png
├── fits/                         # acpnl_fit_*.rds (objetos princals; 1 por script)
├── libs/
│   └── Rlib_r40/                 # pacotes p/ R 4.0.5 (Gifi 0.3-9 — reproduz o TCC)
├── rrun.ps1                      # executor (escolhe Rscript + lib pela versão)
└── README.md
```

## Como rodar

```powershell
# Cada script gera seu fit em fits/ e os 3 plots (scree, loadplot, transplot)
# em resultados/plots/. O pré-processamento comum está em scripts/get_data.r,
# carregado automaticamente por cada um deles.
.\rrun.ps1 scripts\acpnl_fit_nom_5d.r
.\rrun.ps1 scripts\acpnl_fit_ord_5d.r
.\rrun.ps1 scripts\acpnl_fit_nom_4d.r
.\rrun.ps1 scripts\acpnl_fit_nom_5d_splines.r
```

Caso a política de execução bloqueie: `powershell -ExecutionPolicy Bypass -File .\rrun.ps1 ...`

## Resultado da verificação (out/2026)

- **Dados**: `dados/olist.csv` após o pré-processamento (`delivered`,
  `actual_time_to_shipping > 0`, 7 variáveis, `drop_na`) → **5.762 observações**,
  igual ao TCC; frequências da Figura 12 batem exatamente.
- **ACPNL**: as 4 rodadas reproduzem o TCC com exatidão
  (Tabelas 4, 6, 8 e 10 — loadings, autovalores, VAF e comunalidades):
  1. Nominal, 5 dimensões — autovalores 1.9307 1.3416 1.2059 0.7937 0.6517
  2. Ordinal (ATD, ODO, SDO, RS, TPV), 5 dimensões — 1.9339 1.3416 1.2037 0.7938 0.6505
  3. Nominal, 4 dimensões — 1.9330 1.3410 1.1982 0.8094
  4. Nominal, 5 dimensões com splines — 1.9197 1.3175 1.1844 0.8180 0.6589
- **Figuras**: padrões idênticos aos descritos no TCC (RS crescente nas rodadas
  1/2/4 e decrescente na rodada 4D; ATD/TPV monotônicos; PT/ATS alternantes).
- **Única divergência (cosmética)**: componentes 6–7 do *scree* (não retidas).
- **Detalhe técnico**: o Gifi 1.0-0 (2025) mudou o comportamento do `princals`
  e não reproduz os números; por isso o projeto fixa o R 4.0.5 + Gifi 0.3-9.
