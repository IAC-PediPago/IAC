param(
  [Parameter(Mandatory=$true)][string]$Playbook,
  [string]$Inventory = "ansible/inventories/dev/hosts.ini",
  [string]$ExtraVars = ""
)

$ErrorActionPreference = "Stop"

# Ubicarnos en raíz del repo
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repoRoot

# Imagen (cacheada)
$imageName = "pedidos-pagos-ansible:dev"

Write-Host "Building Ansible image: $imageName"
docker build -t $imageName -f tools/ansible/Dockerfile tools/ansible

# Variables AWS: se pasan por env si existen en la máquina/Jenkins
$envKeys = @(
  "AWS_ACCESS_KEY_ID",
  "AWS_SECRET_ACCESS_KEY",
  "AWS_SESSION_TOKEN",
  "AWS_DEFAULT_REGION",
  "AWS_REGION"
)

$envArgs = @()
foreach ($k in $envKeys) {
  $val = [Environment]::GetEnvironmentVariable($k)
  if (-not [string]::IsNullOrWhiteSpace($val)) {
    $envArgs += @("-e", "$k=$val")
  }
}

# Montaje repo
$mount = "$($repoRoot.Path):/workspace"

# Extra vars opcionales
$extra = @()
if ($ExtraVars -and $ExtraVars.Trim().Length -gt 0) {
  $extra = @("--extra-vars", $ExtraVars)
}

# Normalizar ruta del playbook:
# "ansible/playbooks/validate.yml" -> "playbooks/validate.yml"
$pb = $Playbook
if ($pb.ToLower().StartsWith("ansible/")) {
  $pb = $pb.Substring(8)
}

Write-Host "Running playbook: $Playbook"

docker run --rm `
  -v $mount `
  -w /workspace/ansible `
  @envArgs `
  -e "ANSIBLE_CONFIG=/workspace/ansible/ansible.cfg" `
  $imageName `
  "ansible-playbook -i localhost, -c local -v -e 'ANSIBLE_ROLES_PATH=/workspace/ansible/roles' $pb $($extra -join ' ')"
