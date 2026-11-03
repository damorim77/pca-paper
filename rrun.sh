# rrun.sh - executa um script R com o ambiente fixo deste projeto:
# R 4.0.5 + Gifi 0.3-9 (unico ambiente que reproduz o TCC; ver AGENTS.md).
# Linux/SteamOS: usa o conda env libs/mamba_r40 (criado por setup/setup_r40_linux.sh).
# Contraparte no Windows: rrun.ps1.
#
# Uso:
#   ./rrun.sh scripts/acpnl_fit_nom_5d.r
#   ./rrun.sh scripts/acpnl_fit_ord_5d.r --args valor1
#
# Nenhum caminho do R no sistema e necessario: todo o R fica no projeto.

set -e

# Scripts R usam caminhos relativos a raiz do projeto (dados/, fits/, resultados/)
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT"

MICROMAMBA="$ROOT/libs/bin/micromamba"
ENV="$ROOT/libs/mamba_r40"

if [ -x "$MICROMAMBA" ] && [ -x "$ENV/bin/Rscript" ]; then
  exec "$MICROMAMBA" run -p "$ENV" Rscript "$@"
fi

# Fallback: Rscript do sistema. O projeto exige exatamente 4.0.5.
if command -v Rscript >/dev/null 2>&1; then
  V=$(Rscript -e 'cat(as.character(getRversion()))' 2>/dev/null)
  if [ "$V" = "4.0.5" ]; then
    exec Rscript "$@"
  fi
  echo "ERRO: Rscript do sistema e $V; o projeto exige 4.0.5." >&2
fi
echo "ERRO: ambiente do projeto ausente (libs/mamba_r40). Rode: ./setup/setup_r40_linux.sh" >&2
exit 1
