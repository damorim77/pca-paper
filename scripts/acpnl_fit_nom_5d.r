# fit_nom_5d.r - ACPNL com quantificacoes NOMINAIS, 5 dimensoes
# Rodada 1 do TCC (Tabela 4; Figuras 14, 15 e 16).
# Autovalores de referencia: 1.9307 1.3416 1.2059 0.7937 0.6517

source("scripts/get_data.r")

fit_nom <- df %>% princals(ndim = 5, ordinal = FALSE)

print(summary(fit_nom))

saveRDS(fit_nom, 'fits/acpnl_fit_nom_5d.rds')
figuras(fit_nom, 'nom5d')
