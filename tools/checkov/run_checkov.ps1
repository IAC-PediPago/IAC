# tools/checkov/run_checkov.ps1
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$reports  = Join-Path $repoRoot "tools\checkov\reports"
$config   = "/work/tools/checkov/.checkov.yml"

New-Item -ItemType Directory -Force -Path $reports | Out-Null

Write-Host "==> Running Checkov (CLI output)"
docker run --rm `
  -v "${repoRoot}:/work" `
  -w /work `
  bridgecrew/checkov:latest `
  --config-file $config `
  -d iac `
  -o cli

Write-Host "==> Running Checkov (JSON output -> tools/checkov/reports)"
docker run --rm `
  -v "${repoRoot}:/work" `
  -w /work `
  bridgecrew/checkov:latest `
  --config-file $config `
  -d iac `
  -o json `
  --output-file-path /work/tools/checkov/reports/checkov.json

Write-Host "==> Done. Reports folder: tools/checkov/reports"
