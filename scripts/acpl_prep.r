# acpl_prep.r - Preparacao da base BINARIA para a ACP Logistica (comum aos fits acpl_*)
# Reaproveita o tratamento do get_data.r (filtros + binning OneR) e binariza:
#   - RS: binaria, "boa" = review_score > 3 (4 ou 5), "ruim" caso contrario
#   - ODO, SDO: ja 0/1 (um dummy cada)
#   - ATS, ATD, TPV: dummies dos bins OneR (o 1o nivel e a referencia, sem dummy)
#   - PT: dummies por tipo (o 1o nivel alfabetico e a referencia)
# Codificacao com efeito de intercepto (main_effects = TRUE): por variavel,
# uma das categorias vira referencia (sem dummy) para evitar colinearidade.
#
# Supoe diretorio de trabalho = raiz do projeto (rrun.ps1 garante isso).
# Disponibiliza: X (matriz binaria n x q), codif (metadados da codificacao)
# e helpers de figura (acpl_scree, acpl_loadplot, acpl_transplot).

source("scripts/get_data.r")

require(logisticPCA)

# - Variaveis categoricas para a codificacao binaria
#   (RS e binarizada antes do dummy; o resto usa os bins/categorias ja em df)

# (RS vem como factor dos bins OneR: converter p/ numero antes do corte)
rs_num <- as.numeric(as.character(df$RS))
df$RS <- factor(ifelse(rs_num > 3, "boa", "ruim"), levels = c("ruim", "boa"))

vars_cat <- c("ATS", "ATD", "ODO", "SDO", "PT", "RS", "TPV")

# - Metadados da codificacao: uma entrada por dummy + a categoria de referencia
#   coluna    = nome da coluna em X
#   variavel  = variavel original
#   nivel     = categoria observada que o dummy representa (NA se referencia)
#   rotulo    = rotulo legivel da categoria
#   is_ref    = TRUE para a categoria sem dummy

codif <- data.frame(
  coluna   = character(0),
  variavel = character(0),
  nivel    = character(0),
  rotulo   = character(0),
  is_ref   = logical(0)
)

X_parts <- list()
for (v in vars_cat) {
  niveis <- levels(df[[v]])
  for (j in seq_along(niveis)) {
    is_ref <- (j == 1L)
    col <- ""
    if (!is_ref) {
      col <- if (v == "RS") "RS_boa" else paste0(v, "_", j)
      X_parts[[v]] <- cbind(X_parts[[v]],
                            as.integer(df[[v]] == niveis[j]))
    }
    codif <- rbind(codif, data.frame(
      coluna   = col,
      variavel = v,
      nivel    = niveis[j],
      rotulo   = as.character(niveis[j]),
      is_ref   = is_ref
    ))
  }
}
X <- do.call(cbind, X_parts)
colnames(X) <- codif$coluna[!codif$is_ref]

# - Rotulo curto para os eixos dos graficos:
#   bins de metricas: "ATS b2" (2o bin); ODO/SDO: "ODO=1"; PT: "PT <tipo>";
#   RS: "boa"/"ruim". Referencias ficam sem rotulo (NA).

codif$rot_curto <- sapply(seq_len(nrow(codif)), function(i) {
  v <- codif$variavel[i]
  if (v %in% c("ATS", "ATD", "TPV")) {
    paste0(v, " b", sum(codif$variavel[1:i] == v))
  } else if (v %in% c("ODO", "SDO")) {
    paste0(v, "=", codif$rotulo[i])
  } else if (v == "PT") {
    paste0(v, " ", codif$rotulo[i])
  } else {
    codif$rotulo[i]
  }
})

# - Probabilidades fittadas (n x q) a partir de um fit (mu + PCs %*% t(U))

acpl_fitted <- function(fit) {
  # (a aritmetica perde os dimnames de X; a indexacao por nome em
  # acpl_ativacao precisa deles)
  P <- inv.logit.mat(fit$mu + fit$PCs %*% t(fit$U))
  colnames(P) <- codif$coluna[!codif$is_ref]
  P
}

# - Quantificacoes para o transplot analogo: para cada categoria, o
#   log-odds medio fittado do proprio dummy (parametro natural),
#   relativo a categoria de referencia (que vale 0 por construcao).
#   E o análogo das quantificacoes do transplot da ACPNL.

acpl_quant <- function(fit) {
  H <- fit$mu + fit$PCs %*% t(fit$U)
  colnames(H) <- codif$coluna[!codif$is_ref]
  do.call(rbind, lapply(vars_cat, function(v) {
    sub <- codif[codif$variavel == v, ]
    do.call(rbind, lapply(seq_len(nrow(sub)), function(i) {
      eta <- if (sub$is_ref[i]) 0 else mean(H[, sub$coluna[i]])
      data.frame(variavel = v, nivel = sub$nivel[i],
                 rot_curto = sub$rot_curto[i], logodds = eta,
                 stringsAsFactors = FALSE)
    }))
  }))
}

# - Figuras: scree (deviance explained por k), loadplot (U, comps 1 vs 2)
#   e transplot analogo (ativacao por categoria). Grava em resultados/plots
#   com o padrao acpl_fig_<id>_<tipo>.png. `scree_k` = vetor de deviance
#   explained de cada fit k=1..7.

# - scree_k: desvio explicado ACUMULADO (prop_deviance_expl) de k=1..7.
#   O scree plot clássico mostra o desvio explicado POR COMPONENTE
#   (incremental), que deve decrescer; por isso diferenciamos os acumulados.
acpl_scree <- function(scree_k, id) {
  inc <- c(scree_k[1], diff(scree_k))   # desvio explicado por componente
  png(paste0('resultados/plots/acpl_fig_', id, '_scree.png'),
      width = 900, height = 700, res = 120)
  plot(seq_along(inc), inc, type = "b", pch = 19,
       xlab = "Number of components", ylab = "Deviance explained by component",
       main = "Scree Plot",
       ylim = range(inc, 0) * c(0.95, 1.05))
  abline(v = 5, lty = 3, col = "gray40")
  abline(h = 0, lty = 1, col = "gray80")
  dev.off()
}

acpl_loadplot <- function(fit, id) {
  U <- fit$U
  labs <- codif$rot_curto[!codif$is_ref]
  vars_dum <- codif$variavel[!codif$is_ref]
  cores <- setNames(
    c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
      "#0072B2", "#D55E00", "#CC79A7"),
    unique(codif$variavel)
  )
  col_pts <- cores[vars_dum]
  # - deslocamento vertical deterministico p/ rotulos proximos
  #   (multiplas passadas: deslocar um rotulo pode criar novo conflito)
  off <- rep(0, nrow(U))
  for (pass in 1:5) {
    conflitou <- FALSE
    for (i in seq_len(nrow(U))) {
      for (j in seq_len(nrow(U))) {
        if (i == j) next
        if (abs(U[i, 1] - U[j, 1]) < 0.18 &&
            abs(U[i, 2] + off[i] - U[j, 2] - off[j]) < 0.045) {
          off[i] <- off[j] + 0.05 * sign(if (U[i, 2] >= U[j, 2]) 1 else -1)
          conflitou <- TRUE
        }
      }
    }
    if (!conflitou) break
  }
  png(paste0('resultados/plots/acpl_fig_', id, '_loadplot.png'),
      width = 1000, height = 760, res = 120)
  op <- par(mar = c(4.5, 4.5, 3, 1))
  plot(U[, 1], U[, 2], pch = 19, cex = 0.7, asp = 1, col = col_pts,
       xlab = "Component 1", ylab = "Component 2", main = "Loadings Plot",
       xlim = range(U[, 1], 0) * 1.35, ylim = range(U[, 2], 0) * 1.35)
  abline(h = 0, v = 0, lty = 3, col = "gray60")
  pos_lab <- ifelse(U[, 1] < -0.15, 2, 4)
  text(U[, 1], U[, 2] + off, labels = labs, pos = pos_lab,
       cex = 0.68, col = col_pts, xpd = TRUE)
  legend("bottomright", legend = names(cores), col = cores, pch = 19,
         cex = 0.75, bty = "o", bg = adjustcolor("white", 0.8),
         box.col = adjustcolor("white", 0))
  par(op)
  dev.off()
}

acpl_transplot <- function(fit, id) {
  atv <- acpl_quant(fit)
  png(paste0('resultados/plots/acpl_fig_', id, '_transplot.png'),
      width = 1400, height = 900, res = 120)
  op <- par(mfrow = c(4, 2), mar = c(5.5, 4.5, 3, 1))
  for (v in vars_cat) {
    d <- atv[atv$variavel == v, ]
    plot(seq_len(nrow(d)), d$logodds, type = "b", pch = 19,
         xlab = "Observed", ylab = "Transformed (log-odds)",
         main = v, xaxt = "n")
    abline(h = 0, lty = 3, col = "gray60")
    axis(1, at = seq_len(nrow(d)), labels = d$rot_curto, las = 2,
         cex.axis = 0.7)
  }
  par(op)
  dev.off()
}
