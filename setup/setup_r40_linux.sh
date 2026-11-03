# setup_r40_linux.sh - prepara o ambiente Linux (incl. SteamOS) deste projeto:
#   1. micromamba estatico em libs/bin (baixa se ausente; ~20 MB);
#   2. conda env libs/mamba_r40 com R 4.0.5 + toolchain (gcc/gfortran do
#      conda-forge, sysroot, make, pkg-config);
#   3. lib de pacotes libs/Rlib_r40_linux: R packages EM FONTE, versoes
#      travadas da lib Windows (Gifi 0.3-9 incl.; detalhe em
#      setup/install_lib_r40_linux.r).
#
# Espaco necessario: ~1.5 GB. Nao requer root ( tudo mora no repositorio ).
# Windows: nada a fazer - ambiente equivalente fixado em rrun.ps1 + libs/Rlib_r40.
#
# Uso:  ./setup/setup_r40_linux.sh

set -e

# Repositorio = um nivel acima da pasta scripts/
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

MICROMAMBA="$ROOT/libs/bin/micromamba"
ENV="$ROOT/libs/mamba_r40"

if [ ! -x "$MICROMAMBA" ]; then
  echo "baixando micromamba (estatico)..."
  mkdir -p "$ROOT/libs/bin"
  curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
    | tar -xvj --strip-components=1 -C "$ROOT/libs/bin" bin/micromamba
fi

if [ ! -x "$ENV/bin/Rscript" ]; then
  echo "criando env libs/mamba_r40 (R 4.0.5 + toolchain; ~1 GB de download)..."
  "$MICROMAMBA" create -y -p "$ENV" -c conda-forge \
    r-base=4.0.5 gcc_linux-64 gxx_linux-64 gfortran_linux-64 \
    sysroot_linux-64 libstdcxx-ng make pkg-config
fi

"$MICROMAMBA" run -p "$ENV" Rscript -e 'cat("R:", R.version.string, "\n")'

# - Flags de compilacao: gcc moderno (>= 15) tem C23 como default e quebra
#   fontes da era 2020 (mgcv usa 'true' como variavel; survival usa prototipos
#   K&R). gnu17 recupera a semantica antiga sem perder C99/Mixed declarations.
#   doc: R_MAKEVARS_USER sobrepoe o Makeconf sem afetar o sistema.
MAKEVARS="$ROOT/libs/Makevars_r40_linux"
if [ ! -w "$MAKEVARS" ] && [ ! -e "$MAKEVARS" ]; then
  {
    echo "# usado por setup/setup_r40_linux.sh na compilacao da lib em fonte"
    echo "CFLAGS += -std=gnu17"
    echo "CXXFLAGS += -std=gnu17"
    echo "FFLAGS += -std=gnu17"
    echo "FCFLAGS += -std=gnu17"
  } > "$MAKEVARS"
fi

echo "instalando/verificando lib de pacotes (versoes da epoca; pode demorar)..."
R_MAKEVARS_USER="$MAKEVARS" "$MICROMAMBA" run -p "$ENV" Rscript setup/install_lib_r40_linux.r

echo
echo "Ambiente pronto. Rodar os scripts via: ./rrun.sh scripts/<script>.r"
