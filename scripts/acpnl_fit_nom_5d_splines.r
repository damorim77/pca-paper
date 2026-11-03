# fit_nom_5d_splines.r - ACPNL com quantificacoes NOMINAIS, 5 dimensoes, via splines
# Rodada 4 do TCC (Tabela 10; Figuras 23, 24 e 25).
# Autovalores de referencia: 1.9197 1.3175 1.1844 0.8180 0.6589

source("scripts/get_data.r")

fit_nom_splines <- df %>% princals(ndim = 5, ordinal = FALSE, knots = knotsGifi(df, 'E'))

print(summary(fit_nom_splines))

saveRDS(fit_nom_splines, 'fits/acpnl_fit_nom_5d_splines.rds')
figuras(fit_nom_splines, 'nom5d_spl')
