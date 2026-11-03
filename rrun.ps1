# rrun.ps1 - executa um script R com o ambiente fixo deste projeto:
# R 4.0.5 + Gifi 0.3-9 (unico ambiente que reproduz o TCC; ver AGENTS.md).
#
# Uso:
#   .\rrun.ps1 scripts\acpnl_fit_nom_5d.r
#   .\rrun.ps1 script.r --args argumento1 valor2   # argumentos extras para o script R
#
# Parametros:
#   -Script : caminho do script .r a executar (obrigatorio)
#   -RArgs  : argumentos passados ao script R (apos o nome do script)

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Script,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$RArgs
)

$ErrorActionPreference = "Stop"

# Scripts R usam caminhos relativos a raiz do projeto (dados/, fits/, resultados/)
Set-Location $PSScriptRoot

$rscript = "C:\Program Files\R\R-4.0.5\bin\Rscript.exe"

if (-not (Test-Path $rscript)) {
    throw "Rscript nao encontrado: $rscript"
}

# Resolve caminho do script relativo ao diretorio atual
$scriptPath = Resolve-Path $Script -ErrorAction Stop

if ($RArgs) {
    & $rscript $scriptPath @RArgs
} else {
    & $rscript $scriptPath
}

exit $LASTEXITCODE
