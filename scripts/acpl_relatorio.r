# acpl_relatorio.r - Relatorio PDF da analise de ACP Logistica
# Gera um HTML auto-contido (tabelas extraidas dos fits salvos) e converte
# para PDF via Microsoft Edge em modo headless.
#
# Saida: resultados/relatorio_acp_logistica.pdf
# (HTML intermediario em %TEMP%/opencode)

source("scripts/acpl_prep.r")

fit_mm  <- readRDS("fits/acpl_fit_5d_mm.rds")
fit_cvx <- readRDS("fits/acpl_fit_5d_convex.rds")

# - scree recomputado (fits deterministicos: mesmos valores dos scripts de fit)
scree_mm  <- sapply(1:7, function(k) logisticPCA(X, k = k, main_effects = TRUE,
  m = 4, max_iters = 5000, conv_criteria = 1e-5, quiet = TRUE)$prop_deviance_expl)
scree_cvx <- sapply(1:7, function(k) convexLogisticPCA(X, k = k, main_effects = TRUE,
  max_iters = 5000, conv_criteria = 1e-6, quiet = TRUE)$prop_deviance_expl)

q_mm  <- acpl_quant(fit_mm)
q_cvx <- acpl_quant(fit_cvx)

# ---------------------------------------------------------------- helpers HTML

esc <- function(s) {
  s <- gsub("&", "&amp;", s, fixed = TRUE)
  s <- gsub("<", "&lt;", s, fixed = TRUE)
  s
}

tabela <- function(df, colnames_html) {
  linhas <- apply(df, 1, function(r) {
    celulas <- sapply(seq_along(r)[-1], function(j) {
      v <- r[j]
      num <- suppressWarnings(as.numeric(v))
      if (!is.na(num)) {
        paste0("<td>", format(num, digits = 3, nsmall = 3), "</td>")
      } else {
        paste0("<td>", esc(v), "</td>")
      }
    })
    paste0("<tr><td>", esc(r[1]), "</td>", paste(celulas, collapse = ""),
           "</tr>")
  })
  paste0("<table><thead><tr>", colnames_html, "</tr></thead><tbody>",
         paste(linhas, collapse = ""), "</tbody></table>")
}

# caminho relativo a resultados/ (onde fica o HTML): funciona em qualquer SO
img <- function(arq) paste0('<img src="plots/', arq, '">')

# ---------------------------------------------------------------- tabelas

# codificacao das colunas binarias
tab_cod <- paste0("<table><thead><tr><th>Coluna</th><th>Variável</th>",
  "<th>Categoria observada</th><th>Papel</th></tr></thead><tbody>",
  paste(apply(codif, 1, function(r) paste0(
    "<tr><td>", esc(if (r[["coluna"]] == "") "—" else r[["coluna"]]),
    "</td><td>", esc(r[["variavel"]]), "</td><td>", esc(r[["rotulo"]]),
    "</td><td>", if (r[["is_ref"]] == "TRUE") "referência" else "dummy",
    "</td></tr>")), collapse = ""), "</tbody></table>")

# scree k=1..7
tab_scree <- data.frame(k = paste0("k = ", 1:7),
                        MM = round(scree_mm, 4), Convexo = round(scree_cvx, 4))
tab_scree <- tabela(tab_scree, paste0(
  "<th>Componentes</th><th>Desvio explicado (MM)</th>",
  "<th>Desvio explicado (convexo)</th>"))

# loadings comps 1 e 2 (matriz 1 vs 2)
U_mm  <- fit_mm$U;  rownames(U_mm)  <- codif$rot_curto[!codif$is_ref]
U_cvx <- fit_cvx$U; rownames(U_cvx) <- codif$rot_curto[!codif$is_ref]
tab_load_mm  <- tabela(data.frame(rotulo = rownames(U_mm),
                                  U_mm[, 1:2], check.names = FALSE),
                       paste0("<th>Variável</th><th>Comp. 1</th><th>Comp. 2</th>"))
tab_load_cvx <- tabela(data.frame(rotulo = rownames(U_cvx),
                                  U_cvx[, 1:2], check.names = FALSE),
                       paste0("<th>Variável</th><th>Comp. 1</th><th>Comp. 2</th>"))

# quantificacoes (log-odds)
fmt_quant <- function(q) {
  d <- data.frame(rot_curto = q$rot_curto, variavel = q$variavel,
                  logodds = round(q$logodds, 3))
  tabela(d, paste0("<th>Categoria</th><th>Variável</th>",
                   "<th>Log-odds (ref. = 0)</th>"))
}

# ---------------------------------------------------------------- HTML

html <- paste0(
'<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8">',
'<style>
  @page { size: A4; margin: 2cm 1.8cm; }
  body { font-family: Georgia, "Times New Roman", serif; font-size: 11pt;
         line-height: 1.45; color: #1a1a1a; }
  h1 { font-size: 17pt; border-bottom: 2px solid #333; padding-bottom: 6px; }
  h2 { font-size: 13.5pt; margin-top: 22px; page-break-after: avoid; }
  h3 { font-size: 12pt; page-break-after: avoid; }
  p { text-align: justify; margin: 8px 0; }
  table { border-collapse: collapse; margin: 10px 0; font-size: 9pt;
          font-family: Arial, sans-serif; }
  th, td { border: 1px solid #bbb; padding: 3px 8px; text-align: left; }
  th { background: #eee; }
  img { max-width: 100%; display: block; margin: 10px auto; }
  .secao { page-break-before: always; }
  .res { background: #f4f4f8; border-left: 4px solid #556; padding: 8px 12px;
         margin: 12px 0; font-size: 10.5pt; }
  .fig-legenda { font-size: 9pt; color: #444; text-align: center;
                 font-family: Arial, sans-serif; margin: 2px 0 14px; }
  .peq { font-size: 9.5pt; color: #444; }
</style></head><body>

<h1>Análise de Componentes Principais Logística (ACP Logística)<br>
<span style="font-size:12pt;font-weight:normal">Complemento da análise ACPNL do TCC — conjunto Olist (abril/2018)</span></h1>

<p>Este relatório documenta a aplicação da <b>ACP Logística</b> ao mesmo conjunto de
dados da ACPNL do TCC (5.762 pedidos, mesmos filtros e binning OneR de
<code>scripts/get_data.r</code>). O objetivo é cobrir o gap apontado no resumo do
trabalho, que menciona a ACP Logística (Capítulo 4) mas reporta apenas a análise
ACPNL (Capítulo 5.3). Foram rodadas duas estimativas com 5 componentes: o algoritmo
de <b>Majoração-Minimização</b> (MM) e o de <b>Relaxamento convexo</b>, ambos de
Landgraf e Lee (2015), via R <i>package</i> <code>logisticPCA</code> 0.2 (Landgraf).</p>

<h3>Variáveis utilizadas</h3>
<p>De-para entre os nomes originais da base Olist (<code>dados/olist.csv</code>) e os nomes usados nas análises ACPNL e ACP Logística:</p>
<div class="peq">Dicionário de variáveis (7 variáveis originais)</div>
<table><thead><tr><th>Nome original</th><th>Nome usado</th><th>Descrição</th></tr></thead><tbody>
<tr><td>actual_time_to_shipping</td><td>ATS</td><td>Tempo real de postagem/envio (dias)</td></tr>
<tr><td>actual_time_to_deliver</td><td>ATD</td><td>Tempo real de entrega (dias)</td></tr>
<tr><td>order_delivered_onschedule</td><td>ODO</td><td>Entrega no prazo (0/1)</td></tr>
<tr><td>shipping_delivered_onschedule</td><td>SDO</td><td>Postagem no prazo (0/1)</td></tr>
<tr><td>payment_type</td><td>PT</td><td>Tipo de pagamento (boleto, credit_card, debit_card, voucher)</td></tr>
<tr><td>review_score</td><td>RS</td><td>Avaliação da compra (1 a 5)</td></tr>
<tr><td>total_payment_value</td><td>TPV</td><td>Valor total do pagamento (R$)</td></tr>
</tbody></table>

<h2>1. Codificação binária dos dados</h2>
<p>A ACP Logística modela dados <b>binários</b> (Bernoulli). As 7 variáveis da ACPNL
foram recodificadas em 18 colunas binárias. As variáveis métricas mantêm o binning
OneR já usado na ACPNL (uma dummy por faixa, com a primeira faixa como
<b>referência</b>); <code>review_score</code> foi binarizada em <b>boa</b>
(nota &gt; 3, i.e. 4 ou 5) e <b>ruim</b> (1 a 3); <code>payment_type</code> entrou como
dummies por tipo (referência: <i>boleto</i>); ODO e SDO já eram 0/1 (referência: 0).
O modelo inclui efeitos principais (<code>main_effects = TRUE</code>), que jogam o papel
do intercepto — por isso cada variável precisa de uma categoria de referência sem dummy.</p>

<div class="peq">Tabela 1 — Codificação binária (18 colunas; 6 categorias de referência sem dummy)</div>

<h2>2. Método e configuração</h2>
<p><b>MM (Majoração-Minimização):</b> minimiza o desvio de Bernoulli com a restrição
de ortonormalidade plena; garante mínimo local. Parâmetro de penalidade <code>m = 4</code>
(padrão), critério de parada 1e-5, no máximo 5.000 iterações, início determinístico.<br>
<b>Relaxamento convexo:</b> relaxa o domínio não-convexo para a <i>Fantope</i> (projeto
positivo-semidefinido de traço k), com mínimo global garantido na versão relaxada;
critério 1e-6. Em ambos, a estimativa é determinística (sem início aleatório), e o
<i>scree</i> foi construído com fits independentes de k = 1 a 7, análogo à Figura 14 do TCC.</p>

<h2>3. Scree — quanto o modelo explica por número de componentes</h2>
<div class="peq">Tabela 2 — Proporção do desvio de Bernoulli explicada, por k, dos dois algoritmos</div>

<p>Observações: (i) <b>não há ombro acentuado</b> — o ganho por componente fica entre
0,11 e 0,14 até k = 5 e cai para ~0,08 depois. A queda do ganho incremental a partir da
6ª componente indica o cotovelo do scree em k = 5, o que sustenta a retenção de
5 componentes. A escolha coincide com a ACPNL, mas é fundamentada na interpretação do
próprio scree plot, e não apenas por paridade técnica.</p>
(ii) o convexo explica <b>mais desvio em todo k</b> (0,687 vs 0,596 em k = 5) — esperado,
pois ele resolve uma versão <i>relaxada</i> do problema (a medida usa a matriz
relaxada H completa; MM é estritamente rank-5). A comparação justa entre os dois
é pela direção das soluções (loadings), não pelo desvio explicado.</p>

<div class="secao"></div>
<h2>4. Resultados — algoritmo MM (script <code>acpl_fit_5d_mm.r</code>)</h2>
<p>Convergência em <b>48 iterações</b>; desvio explicado (k = 5) = <b>0,5956</b>.</p>

<img src="fig_mm_scree">', '
<div class="fig-legenda">Figura 1 — Scree plot, MM (k = 1..7; linha pontilhada: k = 5)</div>

<h3>4.1 Cargas (componentes 1 e 2)</h3>
<div class="peq">Tabela 3 — Loadings MM, comps 1–2 (U, 18 colunas binárias)</div>

<p><b>Componente 1 — qualidade da entrega.</b> Polos bem definidos: no lado positivo,
cartão de crédito (+0,312), pedido entregue no prazo (+0,257), postagem no prazo
(+0,184) e review boa (+0,211) e ticket alto (TPV b4/b5, +0,23/+0,24); no lado
negativo, as faixas longas de prazo — ATD b5 (−0,420) e ATS b5 (−0,336) — e os tickets
baixos (TPV b2/b3, −0,20/−0,18). A leitura é a mesma história da ACPNL: prazos curtos
e cumpridos andam com satisfação (boa) e tickets maiores; prazos longos andam com
review ruim (categoria de referência) e tickets baixos.</p>
<p><b>Componente 2 — poder de compra / meio de pagamento.</b> Separa ticket alto +
cartão de crédito (TPV b4 +0,359, TPV b5 +0,410, credit_card +0,454) de ticket baixo
(TPV b2 −0,286, TPV b3 −0,294) e voucher (−0,154). É um eixo de <i>valor do pedido</i>,
não de logística — estrutura que a ACPNL não isola, porque lá o TPV foi tratado como
ordinal monotônico e o PT como nominal.</p>

<img src="fig_mm_loadplot">
<div class="fig-legenda">Figura 2 — Loadings plot MM, comps 1–2 (cores por variável)</div>

<h3>4.2 Quantificações (transplot análogo)</h3>
<p>O análogo do gráfico de transformação da ACPNL: para cada categoria, o <b>log-odds
médio</b> do seu próprio dummy relativo à referência (0 por construção). Leitura
relativa <i>dentro</i> de cada variável:</p>
<div class="peq">Tabela 4 — Quantificações MM (log-odds; referências = 0)</div>

<ul>
<li><b>ATS e ATD:</b> trajetórias <b>alternantes</b> (ATS: 0 → −1,49 → −0,51 → −1,54 →
−2,55; ATD: 0 → −0,39 → −1,89 → −1,04 → −2,95). Sem gradiente ordinal estável: as
faixas médias se comportam como categorias nominais, em linha com o resultado da
ACPNL de que ATS deve ficar nominal.</li>
<li><b>ODO e SDO:</b> contraste binário monotônico (−0,70 e −0,99) — por construção
binárias, mas com amplitude relevante: atraso de envio pesa mais que atraso de
entrega na estrutura latente.</li>
<li><b>PT:</b> gradiente decrescente boleto (0) → credit_card (−0,62) → debit_card
(−1,71) → voucher (−1,88). Comportamento de separação nominal, coerente com o PT
alternante da ACPNL.</li>
<li><b>TPV:</b> padrão em <b>U</b> (b1 = 0; b2/b3 ≈ −2,1; b4/b5 ≈ −0,84) — não-monotônico,
o que <b>não</b> reproduz o "notavelmente ordinal" do TPV na ACPNL: a codificação em
dummies permite à ACP Logística expressar não-linearidades que a quantificação
ordinal da ACPNL força a ser reta.</li>
<li><b>RS:</b> contraste único (−0,85), separação forte entre boa/ruim.</li>
</ul>

<img src="fig_mm_transplot">
<div class="fig-legenda">Figura 3 — Transplot análogo MM (log-odds médio por categoria; ref. = 0)</div>

<div class="secao"></div>
<h2>5. Resultados — relaxamento convexo (script <code>acpl_fit_5d_convex.r</code>)</h2>
<p>Convergência em <b>27 iterações</b>; desvio explicado = <b>0,6872</b> (medido na
solução relaxada; ver ressalva da Seção 3).</p>

<img src="fig_cvx_scree">
<div class="fig-legenda">Figura 4 — Scree plot, convexo (k = 1..7; linha pontilhada: k = 5)</div>

<h3>5.1 Cargas (componentes 1 e 2)</h3>
<div class="peq">Tabela 5 — Loadings convexo, comps 1–2 (U projetado no Fantope)</div>

<p><b>Componente 1 — mesma história da qualidade da entrega, mais limpa.</b>
ATD b5 (−0,608) e ATS b5 (−0,425) dominam o polo negativo; ODO = 1 (+0,368), SDO = 1
(+0,271), review boa (+0,358) e ATD b2 (+0,241) o positivo. O eixo reproduz o
Componente 1 da MM com cargas mais concentradas (consequência da projeção no
Fantope).</p>
<p><b>Componente 2 — meio de pagamento e ticket.</b> Aqui o convexo separa o eixo de
forma mais nítida que a MM: credit_card (+0,680) quase sozinho no polo positivo,
com TPV b5 (+0,453) e TPV b4 (+0,244); voucher (−0,263), debit_card (−0,140) e
TPV b2 (−0,341) / TPV b3 (−0,244) no negativo. Confirma a leitura da MM: existe
uma dimensão latente de <b>valor do pedido associada ao meio de pagamento</b>.</p>

<img src="fig_cvx_loadplot">
<div class="fig-legenda">Figura 5 — Loadings plot convexo, comps 1–2</div>

<h3>5.2 Quantificações (transplot análogo)</h3>
<div class="peq">Tabela 6 — Quantificações convexo (log-odds; referências = 0)</div>

<ul>
<li><b>ATS:</b> quase monotônica decrescente (0 → −0,69 → −0,77 → −0,82 → −1,31) —
o convexo, buscando o mínimo global da versão relaxada, organiza as faixas em
gradiente, enquanto a MM (mínimo local) as deixa alternantes.</li>
<li><b>ATD:</b> quase monotônica (0 → −0,56 → −0,75 → −0,72 → −1,69), com leve não
monotonicidade entre b3 e b4.</li>
<li><b>PT:</b> gradiente decrescente boleto (0) → credit (−0,45) → debit (−0,92) →
voucher (−1,03), como na MM.</li>
<li><b>TPV:</b> mantém o padrão em U (0; −1,03; −1,04; −0,73; −0,72) — a não
linearidade do valor do pedido é robusta entre algoritmos.</li>
<li><b>ODO/SDO/RS:</b> idênticos em forma aos da MM, com amplitudes menores
(−0,35/−0,56/−0,37), refletindo a distribuição mais suave da solução relaxada.</li>
</ul>

<img src="fig_cvx_transplot">
<div class="fig-legenda">Figura 6 — Transplot análogo convexo (log-odds médio por categoria; ref. = 0)</div>

<div class="secao"></div>
<h2>6. Síntese — MM vs convexo, e relação com a ACPNL</h2>
<ul>
<li><b>Os dois algoritmos contam a mesma história nos dois primeiros eixos</b>:
(1) qualidade da entrega (prazos curtos/cumpridos + review boa + ticket alto) e
(2) valor do pedido associado ao meio de pagamento (credit_card/ticket alto vs
boleto-voucher/ticket baixo). A estrutura é estável entre mínimos locais (MM) e
global relaxado (convexo) — indício de solução robusta.</li>
<li><b>Diferença principal:</b> nas faixas intermediárias de ATS/ATD, a MM alterna
enquanto o convexo alinha quase monotônico. Como o convexo minimiza o desvio
globalmente na versão relaxada, a quase-ordinalidade dele é a organização "suave"
dos mesmos dados; a MM, presa a um mínimo local, enfatiza os contrastes
não-monotônicos.</li>
<li><b>Convergência com a ACPNL:</b> PT nominal/alternante e a separação forte de
ODO/SDO/RS se repetem. Divergência: o TPV, "notavelmente ordinal" na ACPNL,
aparece <b>não-monotônico (em U)</b> aqui nos dois algoritmos — evidência de que a
relação do valor do pedido com a estrutura latente não é linear nem ordinal.</li>
<li><b>Limitações:</b> deviance explicado dos dois métodos não é diretamente
comparável (o convexo usa a solução relaxada completa na medida); as
quantificações em log-odds resumem efeitos marginais médios (não são
restrições do modelo, como as quantificações exatas da ACPNL); e a binarização
por dummies multiplica a dimensão (18 colunas), o que dilui a noção de
"autovalor por variável" da ACPNL — daí o uso do desvio explicado como
critério de retenção.</li>
</ul>

<p class="peq"><b>Reprodutibilidade:</b> ambiente R 4.0.5 + logisticPCA 0.2
(<code>libs/Rlib_r40</code>), fits determinísticos. Comandos:
<code>.\\rrun.ps1 scripts\\acpl_fit_5d_mm.r</code>,
<code>.\\rrun.ps1 scripts\\acpl_fit_5d_convex.r</code>,
<code>.\\rrun.ps1 scripts\\acpl_relatorio.r</code>.
Artefatos: <code>fits/acpl_fit_5d_{mm,convex}.rds</code>,
<code>resultados/plots/acpl_fig_{mm5d,cvx5d}_*.png</code>.</p>

</body></html>')

# injeção das tabelas e figuras
html <- sub("<div class=\"peq\">Tabela 1[^<]*</div>",
            paste0('<div class="peq">Tabela 1 — Codificação binária (18 colunas; 6 categorias de referência sem dummy)</div>\n', tab_cod),
            html, fixed = FALSE)
html <- sub('<div class="peq">Tabela 2 — Proporção do desvio de Bernoulli explicada, por k, dos dois algoritmos</div>',
            paste0('<div class="peq">Tabela 2 — Proporção do desvio de Bernoulli explicada, por k, dos dois algoritmos</div>\n', tab_scree),
            html, fixed = TRUE)
html <- sub('<div class="peq">Tabela 3 — Loadings MM, comps 1–2 (U, 18 colunas binárias)</div>',
            paste0('<div class="peq">Tabela 3 — Loadings MM, comps 1–2 (U, 18 colunas binárias)</div>\n', tab_load_mm),
            html, fixed = TRUE)
html <- sub('<div class="peq">Tabela 4 — Quantificações MM (log-odds; referências = 0)</div>',
            paste0('<div class="peq">Tabela 4 — Quantificações MM (log-odds; referências = 0)</div>\n', fmt_quant(q_mm)),
            html, fixed = TRUE)
html <- sub('<div class="peq">Tabela 5 — Loadings convexo, comps 1–2 (U projetado no Fantope)</div>',
            paste0('<div class="peq">Tabela 5 — Loadings convexo, comps 1–2 (U projetado no Fantope)</div>\n', tab_load_cvx),
            html, fixed = TRUE)
html <- sub('<div class="peq">Tabela 6 — Quantificações convexo (log-odds; referências = 0)</div>',
            paste0('<div class="peq">Tabela 6 — Quantificações convexo (log-odds; referências = 0)</div>\n', fmt_quant(q_cvx)),
            html, fixed = TRUE)

html <- sub('<img src="fig_mm_scree">',  img("acpl_fig_mm5d_scree.png"),  html, fixed = TRUE)
html <- sub('<img src="fig_mm_loadplot">',  img("acpl_fig_mm5d_loadplot.png"),  html, fixed = TRUE)
html <- sub('<img src="fig_mm_transplot">', img("acpl_fig_mm5d_transplot.png"), html, fixed = TRUE)
html <- sub('<img src="fig_cvx_scree">',  img("acpl_fig_cvx5d_scree.png"),  html, fixed = TRUE)
html <- sub('<img src="fig_cvx_loadplot">',  img("acpl_fig_cvx5d_loadplot.png"),  html, fixed = TRUE)
html <- sub('<img src="fig_cvx_transplot">', img("acpl_fig_cvx5d_transplot.png"), html, fixed = TRUE)

# - grava HTML e converte p/ PDF (Edge headless, so Windows)
html_tmp <- file.path("resultados", "relatorio_acp_logistica.html")
writeLines(html, html_tmp, useBytes = TRUE)

edge <- "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
pdf  <- "C:/projects/pca-paper/resultados/relatorio_acp_logistica.pdf"
if (.Platform$OS.type == "windows" && file.exists(edge)) {
  system(paste(shQuote(edge),
               "--headless --disable-gpu --no-pdf-header-footer",
               paste0('--user-data-dir="', file.path(tempdir(), "edge_acpl"), '"'),
               paste0('--print-to-pdf="', pdf, '"'),
               paste0('"file:///', html_tmp, '"')),
         wait = TRUE)
  cat("PDF:", if (file.exists(pdf)) "gerado" else "FALHOU", "->", pdf, "\n")
} else {
  cat("Edge nao encontrado; HTML em:", html_tmp, "\n")
}
