# acpl_fit_5d_convex.r - ACP Logistica, 5 dimensoes, algoritmo de
# Relaxamento convexo (Landgraf e Lee, 2015) via convexLogisticPCA().
# Mesma codificacao binaria e especificacao do acpl_fit_5d_mm.r
# (o convexo resolve uma versao relaxada do problema, com minimo global
# garantido na versao relaxada; os loadings saem projetados no Fantope).
#
# Scree: fits k = 1..7 (deviance explained).

source("scripts/acpl_prep.r")

scree_k <- sapply(1:7, function(k) {
  convexLogisticPCA(X, k = k, main_effects = TRUE,
                    max_iters = 5000, conv_criteria = 1e-6,
                    quiet = TRUE)$prop_deviance_expl
})

fit <- convexLogisticPCA(X, k = 5, main_effects = TRUE,
                         max_iters = 5000, conv_criteria = 1e-6, quiet = TRUE)

# - Sumario da execucao (console)
cat("\n=== ACP Logistica 5D - Relaxamento convexo (convexLogisticPCA) ===\n")
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

saveRDS(fit, "fits/acpl_fit_5d_convex.rds")
acpl_scree(scree_k, "cvx5d")
acpl_loadplot(fit, "cvx5d")
acpl_transplot(fit, "cvx5d")
