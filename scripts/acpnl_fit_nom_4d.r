# fit_nom_4d.r - ACPNL com quantificacoes NOMINAIS, 4 dimensoes
# Rodada 3 do TCC (Tabela 8; Figuras 20, 21 e 22).
# Autovalores de referencia: 1.9330 1.3410 1.1982 0.8094
# Nota: nesta rodada a variavel RS apresenta quantificacoes decrescentes
# (discutido nas linhas 1730-1732 do TCC).

source("scripts/get_data.r")

fit_nom2 <- df %>% princals(ndim = 4, ordinal = FALSE)

print(summary(fit_nom2))

saveRDS(fit_nom2, 'fits/acpnl_fit_nom_4d.rds')
figuras(fit_nom2, 'nom4d')
