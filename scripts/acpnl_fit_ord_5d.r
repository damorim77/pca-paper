# fit_ord_5d.r - ACPNL com quantificacoes ORDINAIS em ATD, ODO, SDO, RS e TPV
# (ATS e PT permanecem nominais), 5 dimensoes.
# Rodada 2 do TCC (Tabela 6; Figuras 17, 18 e 19).
# Autovalores de referencia: 1.9339 1.3416 1.2037 0.7938 0.6505

source("scripts/get_data.r")

fit_ord <- df %>% princals(ndim = 5, ordinal = c(FALSE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE))

print(summary(fit_ord))

saveRDS(fit_ord, 'fits/acpnl_fit_ord_5d.rds')
figuras(fit_ord, 'ord5d')
