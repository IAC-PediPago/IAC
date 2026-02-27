# tools/lambda/build_lambdas.ps1
$ErrorActionPreference = "Stop"

$repoRoot   = (Resolve-Path "$PSScriptRoot\..\..").Path
$lambdasDir = Join-Path $repoRoot "lambdas"
$outDir     = Join-Path $repoRoot "iac\lambda_artifacts"

if (!(Test-Path $lambdasDir)) {
  throw "No existe la carpeta lambdas/: $lambdasDir"
}

# Crear output dir si no existe
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# ✅ Limpieza: borrar zips antiguos para evitar confusión/artefactos obsoletos
Write-Host "==> Cleaning old artifacts in: $outDir"
Get-ChildItem -Path $outDir -Filter "*.zip" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# Detectar si existe package-lock.json
$hasLock = Test-Path (Join-Path $lambdasDir "package-lock.json")

Write-Host "==> Installing deps inside Docker..."
if ($hasLock) {
  Write-Host "    Using npm ci (package-lock.json found)"
} else {
  Write-Host "    Using npm install (no package-lock.json)"
}

# 1) Instalar dependencias (1 sola vez)
docker run --rm `
  -u "0:0" `
  -v "${repoRoot}:/work" `
  -w /work/lambdas `
  node:20-alpine `
  sh -lc "apk add --no-cache zip >/dev/null && if [ -f package-lock.json ]; then npm ci; else npm install; fi"

# Validar que node_modules exista
if (!(Test-Path (Join-Path $lambdasDir "node_modules"))) {
  throw "No se generó lambdas/node_modules. Revisa el log de npm dentro del contenedor."
}

# 2) Empaquetar (actualizado a tus lambdas nuevas)
$targets = @(
  @{ dir = "orders_create";        zip = "orders_create.zip" },
  @{ dir = "orders_get";           zip = "orders_get.zip" },
  @{ dir = "orders_update_status"; zip = "orders_update_status.zip" },

  @{ dir = "payments_create";      zip = "payments_create.zip" },
  @{ dir = "payments_webhook";     zip = "payments_webhook.zip" },

  @{ dir = "products_list";        zip = "products_list.zip" },

  @{ dir = "notifications_worker"; zip = "notifications_worker.zip" },
  @{ dir = "inventory_worker";     zip = "inventory_worker.zip" }
)

Write-Host "==> Packaging all lambdas..."
foreach ($t in $targets) {
  $dir = $t.dir
  $zip = $t.zip

  $lambdaPath = Join-Path $lambdasDir $dir
  if (!(Test-Path $lambdaPath)) {
    throw "No existe la lambda folder: $lambdaPath"
  }

  Write-Host "==> Packaging $dir -> iac/lambda_artifacts/$zip"

  # Armamos comando (incluye package-lock solo si existe)
  $zipCmd = if ($hasLock) {
    "rm -f /work/iac/lambda_artifacts/$zip && zip -r /work/iac/lambda_artifacts/$zip $dir shared node_modules package.json package-lock.json >/dev/null"
  } else {
    "rm -f /work/iac/lambda_artifacts/$zip && zip -r /work/iac/lambda_artifacts/$zip $dir shared node_modules package.json >/dev/null"
  }

  docker run --rm `
    -u "0:0" `
    -v "${repoRoot}:/work" `
    -w /work/lambdas `
    node:20-alpine `
    sh -lc "apk add --no-cache zip >/dev/null && $zipCmd"
}

Write-Host "==> Done. Artifacts in: iac/lambda_artifacts"
Get-ChildItem $outDir | Sort-Object Name | Format-Table Name, Length