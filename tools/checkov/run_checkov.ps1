# tools/checkov/run_checkov.ps1
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$reports  = Join-Path $repoRoot "tools\checkov\reports"

# Crear carpeta de reportes
New-Item -ItemType Directory -Force -Path $reports | Out-Null

Write-Host "==> Pull Checkov image (bridgecrew/checkov:3)"
docker pull bridgecrew/checkov:3

Write-Host "==> Running Checkov (JUnit XML -> tools/checkov/reports/results.xml)"
docker run --rm `
  -v "${repoRoot}:/tf" `
  --workdir /tf `
  bridgecrew/checkov:3 `
  --directory /tf/iac `
  -o junitxml `
  --output-file-path /tf/tools/checkov/reports/results.xml

Write-Host "==> Done."
Write-Host "==> JUnit report: tools/checkov/reports/results.xml"
