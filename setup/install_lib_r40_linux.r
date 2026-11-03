# install_lib_r40_linux.r - reconstroi a lib de pacotes para Linux (R 4.0.5 do
# conda, em libs/mamba_r40), instalando EM FONTE as versoes exatas da lib Windows.
#
# Fonte das versoes: libs/Rlib_r40/*/DESCRIPTION (travadas; built em 2022-04-21).
# Fonte dos tarballs, nesta ordem:
#   1. CRAN Archive (cran-archive.r-project.org e cran.r-project.org) - a versao
#      e garantida pelo nome do arquivo;
#   2. snapshot do Posit Package Manager do dia da construcao da lib Windows
#      (2022-04-21), que contem o Gifi 0.3-9 (ausente do Archive do CRAN) e os
#      "recommended" (MASS/mgcv/Matrix etc. - o ggplot2 3.3.5 Imports do
#      logisticPCA exige MASS/mgcv, e o r-base do conda nao os traz).
# Em todos os casos a versao do tarball e verificada contra a versao alvo.
#
# Uso: setup/setup_r40_linux.sh chama este script. Manualmente, a partir da
# raiz do projeto:
#   libs/bin/micromamba run -p libs/mamba_r40 Rscript install_lib_r40_linux.r

.args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", .args, value = TRUE)
if (length(file_arg) > 0) {
  projeto_dir <- dirname(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
} else {
  projeto_dir <- getwd()
}

libdir <- file.path(projeto_dir, "libs", "Rlib_r40_linux")
srcdir <- file.path(projeto_dir, "libs", "cran_src")
dir.create(libdir, showWarnings = FALSE, recursive = TRUE)
dir.create(srcdir, showWarnings = FALSE, recursive = TRUE)

if (getRversion() != "4.0.5") {
  stop(sprintf("instalador exige R 4.0.5; R atual: %s (use setup/setup_r40_linux.sh)",
               getRversion()))
}
.libPaths(libdir)

# - Versoes travadas (copiadas de libs/Rlib_r40/*/DESCRIPTION)
versoes <- list(
  cli          = "3.2.0",
  colorspace   = "2.0-3",
  cpp11        = "0.4.2",
  crayon       = "1.5.1",
  dplyr        = "1.0.8",
  ellipsis     = "0.3.2",
  fansi        = "1.0.3",
  generics     = "0.1.2",
  Gifi         = "0.3-9",
  glue         = "1.6.2",
  lifecycle    = "1.0.1",
  logisticPCA  = "0.2",
  magrittr     = "2.0.3",
  OneR         = "2.2",
  pillar       = "1.7.0",
  pkgconfig    = "2.0.3",
  purrr        = "0.3.4",
  R6           = "2.5.1",
  rlang        = "1.0.2",
  tibble       = "3.1.6",
  tidyr        = "1.2.0",
  tidyselect   = "1.1.2",
  utf8         = "1.2.2",
  vctrs        = "0.4.1",
  # Dependencias que a lib Windows resolvia na lib de sistema: ggplot2 3.3.5
  # (Imports do logisticPCA) e Arvore de deps. Versoes da epoca (2022-04).
  ggplot2      = "3.3.5",
  digest       = "0.6.29",
  gtable       = "0.3.0",
  isoband      = "0.2.5",
  labeling     = "0.4.2",
  scales       = "1.1.1",
  withr        = "2.4.2",
  munsell      = "0.5.0",
  RColorBrewer = "1.1-2",
  farver       = "2.1.0",
  viridisLite  = "0.4.0",
  # "Recommended" do R exigidos pelo ggplot2/mgcv. Versao NULL = resolver a
  # versao do snapshot 2022-04-21 (sem travamento manual). Nao incluimos
  # survival/lattice: ninguem Importa (apenas Suggests de mgcv/ggplot2).
  MASS         = NULL,
  Matrix       = NULL,
  mgcv         = NULL,
  nlme         = NULL
)

ppm_date <- "2022-04-21"
ppm_src <- sprintf("https://packagemanager.posit.co/cran/%s/src/contrib", ppm_date)

# - Resolve as versoes NULL via indice do snapshot (packages "recommended")
faltam <- names(versoes)[vapply(versoes, is.null, logical(1))]
if (length(faltam) > 0) {
  ap <- available.packages(repos = sprintf("https://packagemanager.posit.co/cran/%s", ppm_date))
  fora <- setdiff(faltam, rownames(ap))
  if (length(fora) > 0) stop(sprintf("versao nao encontrada no snapshot: %s", paste(fora, collapse = ", ")))
  for (p in faltam) versoes[[p]] <- unname(ap[p, "Version"])
}
cat("=== versoes ===\n")
for (p in names(versoes)) cat(sprintf("  %-12s %s\n", p, versoes[[p]]))

# - Download com candidatos (Archive garantido -> snapshot do dia)
baixar <- function(pkg, vers) {
  dest <- file.path(srcdir, sprintf("%s_%s.tar.gz", pkg, vers))
  if (!file.exists(dest)) {
    urls <- c(
      sprintf("https://cran.r-project.org/src/contrib/Archive/%s/%s", pkg, basename(dest)),
      sprintf("https://cran-archive.r-project.org/src/contrib/Archive/%s/%s", pkg, basename(dest)),
      sprintf("%s/%s", ppm_src, basename(dest))
    )
    baixado <- FALSE
    for (u in urls) {
      r <- tryCatch(download.file(u, dest, mode = "wb"), error = function(e) e)
      if (!inherits(r, "error") && identical(as.integer(r), 0L) && file.exists(dest)) {
        # url que respondeu pode ter sido pagina de erro 404; validar magic gzip
        # (conexao binaria crua - gzfile() descomprimiria e mascararia o header)
        fd <- file(dest, "rb"); magic <- readBin(fd, "raw", 3L); close(fd)
        if (identical(magic, as.raw(c(0x1f, 0x8b, 0x08)))) {
          baixado <- TRUE; break
        }
        cat(sprintf("    (arquivo invalido em %s; descarta)\n", u))
        unlink(dest)
      }
    }
    if (!baixado) stop(sprintf("falha ao obter %s_%s (nenhum candidato retornou tarball)", pkg, vers))
  }
  dest
}

# - Extrai versao + dependencias (Depends/Imports/LinkingTo) do tarball
desc_tar <- function(pkg, tarball) {
  tmp <- tempfile(); dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  untar(tarball, files = sprintf("%s/DESCRIPTION", pkg), exdir = tmp)
  m <- read.dcf(file.path(tmp, pkg, "DESCRIPTION"))
  versao <- unname(m[1, "Version"])
  campos <- intersect(c("Depends", "Imports", "LinkingTo"), colnames(m))
  # separa por campo (se colapsar os campos, o "R (>= x)" do Depends engole
  # o item seguinte no sub da versao)
  deps <- unlist(lapply(m[1, campos], strsplit, split = ","))
  deps <- trimws(sub("\\(.*$", "", deps))
  deps <- deps[nzchar(deps) & deps != "R"]
  list(versao = versao, deps = sorted_unique(deps))
}
sorted_unique <- function(x) sort(unique(x))

# - Base do R que o r-base do conda de fato fornece (nunca instalar na lib do
#   projeto; os recommended NAO vem no conda e, se exigidos, sao em 'versoes')
base_r <- c(
  "base", "compiler", "datasets", "graphics", "grDevices", "grid",
  "methods", "parallel", "splines", "stats", "stats4", "tcltk", "tools",
  "translations", "utils"
)
# (recommended ESTAO em 'versoes': no conda eles NAO vem com o r-base)

# - Ja instalado na lib? (com versao confere)
instalados <- character(0)
disp <- rownames(installed.packages(lib.loc = libdir))
disp_ok <- intersect(names(versoes), disp)
for (p in disp_ok) {
  v <- packageDescription(p, lib.loc = libdir)$Version
  if (identical(v, versoes[[p]])) instalados <- c(instalados, p)
}
falta_instalar <- setdiff(names(versoes), instalados)
cat(sprintf("=== a instalar: %d pacote(s) ===\n", length(falta_instalar)))

rodada <- 0
while (length(falta_instalar) > 0 && rodada < 15) {
  rodada <- rodada + 1
  avanco <- FALSE
  for (p in falta_instalar) {
    tarball <- baixar(p, versoes[[p]])
    d <- desc_tar(p, tarball)
    if (!identical(d$versao, versoes[[p]])) {
      stop(sprintf("tarball de %s: versao %s != %s esperada", p, d$versao, versoes[[p]]))
    }
    faltando <- setdiff(intersect(d$deps, names(versoes)), instalados)
    desconhecidas <- setdiff(d$deps, c(base_r, names(versoes), instalados))
    if (length(desconhecidas) > 0) {
      stop(sprintf("%s_%s depende de: %s - fora do conjunto deste instalador",
                   p, versoes[[p]], paste(desconhecidas, collapse = ", ")))
    }
    if (length(faltando) == 0) {
      # todas as dependencias no nosso conjunto resolvidas: instalar
      cat(sprintf("[%d] instalando %s_%s ...\n", rodada, p, versoes[[p]]))
      ok <- tryCatch({
        install.packages(tarball, lib = libdir, repos = NULL, type = "source")
        TRUE
      }, error = function(e) { message(conditionMessage(e)); FALSE })
      if (!identical(ok, TRUE) || !(p %in% rownames(installed.packages(lib.loc = libdir)))) {
        stop(sprintf("install.packages falhou para %s", p))
      }
      instalados <- c(instalados, p)
      avanco <- TRUE
    } else {
      # deps pendentes; instala em rodada futura
    }
  }
  if (!avanco) {
    stop(sprintf("sem progresso na rodada %d; faltam: %s", rodada,
                 paste(falta_instalar, collapse = ", ")))
  }
  falta_instalar <- setdiff(names(versoes), instalados)
}

# - Verificacao final: carregamento de TUDO, inclusive Gifi/logisticPCA
cat("=== cargas ===\n")
falhas <- character(0)
for (p in names(versoes)) {
  okp <- suppressWarnings(suppressPackageStartupMessages(
    require(p, character.only = TRUE, quietly = TRUE)))
  cat(sprintf("  %-12s %s\n", p, if (isTRUE(okp)) "ok" else "FALHOU"))
  if (!isTRUE(okp)) falhas <- c(falhas, p)
}
if (length(falhas) > 0) {
  stop(sprintf("falha ao carregar: %s", paste(falhas, collapse = ", ")))
}
cat("=== lib completa: ", length(versoes), " pacotes em ", libdir, " ===\n", sep = "")
cat("=== (aparece como .libPaths()[1]: ", .libPaths()[1], ") ===\n", sep = "")
