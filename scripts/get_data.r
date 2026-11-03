# comum_pre_fit.r - Preparacao da base para a ACPNL (comum aos scripts de fit)
# Reproduz o tratamento do Capitulo 5.1 do TCC: pedidos entregues, abril/2018,
# item unico, tempo de postagem > 0, 7 variaveis, sem NA, metricas em faixas
# de iguais quantidades de observacoes (OneR::bin, method='content').
#
# Supoe diretorio de trabalho = raiz do projeto (rrun.ps1/rrun.sh garante isso).
# Disponibiliza: df (dados para o princals) e as libs Gifi/dplyr/tidyr/OneR.

# - Biblioteca de pacotes: relativa ao script (sob 2 niveis: scripts/x.r -> raiz)
# Windows usa a lib binaria original; Linux usa a lib em fonte equivalente
# (mesmas versoes travadas; ver ../setup/install_lib_r40_linux.r).
libnome <- if (.Platform$OS.type == "windows") "Rlib_r40" else "Rlib_r40_linux"
.args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", .args, value = TRUE)
if (length(file_arg) > 0) {
  # via Rscript: usa a pasta do script executado no topo
  projeto_dir <- dirname(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
} else {
  # console interativo: assume raiz do projeto como diretorio de trabalho
  projeto_dir <- getwd()
}
.libPaths(file.path(projeto_dir, "libs", libnome))

require(dplyr)
require(tidyr)
require(Gifi)
require(OneR)

df <- read.csv("dados/olist.csv", na.strings = c("", "NA"))

# - Transformacoes gerais no conjunto de dados

numcols_to_factor <- c(
  'unique_payment_type',
  'shipping_delivered_onschedule',
  'order_delivered_onschedule',
  'order_same_city',
  'order_same_state')

df <- df[df$order_status == 'delivered', ]
df <- df[df$actual_time_to_shipping > 0, ]

df <- df %>%
  mutate_if(~ !is.numeric(.), as.factor) %>%
  mutate_at(all_of(numcols_to_factor), as.factor)

# - Selecionando variaveis da analise

cols_analise <- c(
  'actual_time_to_shipping',
  'actual_time_to_deliver',
  'order_delivered_onschedule',
  'shipping_delivered_onschedule',
  'payment_type',
  'review_score',
  'total_payment_value')

df <- df %>%
  select_at(all_of(cols_analise)) %>%
  drop_na() %>%
  mutate_if(is.numeric, function(x) OneR::bin(x, method = 'content'))

colnames(df) <- c('ATS', 'ATD', 'ODO', 'SDO', 'PT', 'RS', 'TPV')

# - Plots: grava em resultados/plots com o padrao acpnl_fig_<id>_<tipo>.png
figuras <- function(fit, id) {
  png(paste0('resultados/plots/acpnl_fig_', id, '_scree.png'), width = 900, height = 700, res = 120)
  print(plot(fit, plot.type = 'screeplot'))
  dev.off()
  png(paste0('resultados/plots/acpnl_fig_', id, '_loadplot.png'), width = 900, height = 700, res = 120)
  print(plot(fit, plot.type = 'loadplot'))
  dev.off()
  png(paste0('resultados/plots/acpnl_fig_', id, '_transplot.png'), width = 1400, height = 900, res = 120)
  print(plot(fit, plot.type = 'transplot'))
  dev.off()
}
