# acpl_fit_5d_mm.r - ACP Logistica, 5 dimensoes, algoritmo de
# Majoracao-Minimizacao (Landgraf e Lee, 2015) via logisticPCA().
# Codificacao binaria: ver acpl_prep.r (RS binaria > 3; dummies de bins;
# PT em dummies; referencia = 1o nivel de cada variavel).
#
# Inicio sem aleatoriedade (deterministico), m = 4 (limite do parametro
# natural, padrao do pacote). Scree: fits k = 1..7 (deviance explained).

source("scripts/acpl_prep.r")

scree_k <- sapply(1:7, function(k) {
  logisticPCA(X, k = k, main_effects = TRUE, m = 4,
              max_iters = 5000, conv_criteria = 1e-5,
              quiet = TRUE)$prop_deviance_expl
})

fit <- logisticPCA(X, k = 5, main_effects = TRUE, m = 4,
                   max_iters = 5000, conv_criteria = 1e-5, quiet = TRUE)

# - Sumario da execucao (console)
cat("\n=== ACP Logistica 5D - MM (logisticPCA) ===\n")
cat("obs:", nrow(X), " colunas binarias:", ncol(X), "\n")
cat("iteracoes:", fit$iters, "\n")
cat("scree (prop deviance explained, k=1..7):\n")
print(round(scree_k, 4))
cat("deviance explained (k=5):", round(fit$prop_deviance_expl, 4), "\n")
cat("\n-- loadings (U, comps 1-5) --\n")
U <- fit$U
rownames(U) <- codif$rot_curto[!codif$is_ref]
print(round(U, 3))
cat("\n-- quantificacoes por categoria (log-odds medio, ref. = 0) --\n")
atv <- acpl_quant(fit)
atv$logodds <- round(atv$logodds, 4)
print(atv, row.names = FALSE)

saveRDS(fit, "fits/acpl_fit_5d_mm.rds")
acpl_scree(scree_k, "mm5d")
acpl_loadplot(fit, "mm5d")
acpl_transplot(fit, "mm5d")
