# Comandos De Despliegue (Paso A Paso)

## 1) Ir a la raiz del proyecto y analizar estructura
```bash
export ROOT="/mnt/c/Users/Jheyson/Downloads/ProyectoIaC/Proyecto PePa/Proyecto PePa"
cd "$ROOT"

pwd
ls -la
find ansible aws cicd frontend iac lambdas sonarqube tools -maxdepth 3 -type f | sort
```

## 2) Verificar herramientas base
```bash
docker --version
docker compose version
aws --version
terraform -version
ansible --version
node --version
npm --version
zip -v | head -n 1
```

## 3) Configurar credenciales AWS
```bash
export AWS_ACCESS_KEY_ID="TU_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="TU_SECRET_KEY"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_REGION="$AWS_DEFAULT_REGION"

aws sts get-caller-identity
```

## 4) Levantar SonarQube y Jenkins
```bash
cd "$ROOT/sonarqube"
docker compose up -d
docker compose ps

cd "$ROOT/cicd/jenkins"
docker compose up -d --build
docker compose ps
docker exec pedidos-pagos-dev-jenkins cat /var/jenkins_home/secrets/initialAdminPassword

cd "$ROOT"
```

## 5) Bootstrap backend remoto Terraform
```bash
cd "$ROOT/iac/bootstrap/dev"
terraform init
terraform apply -auto-approve

export TF_BACKEND_BUCKET="$(terraform output -raw tfstate_bucket_name)"
export TF_BACKEND_DDB_TABLE="$(terraform output -raw tf_lock_table_name)"
export TF_BACKEND_REGION="$(terraform output -raw aws_region)"

cd "$ROOT"
```

## 6) Empaquetar Lambdas (ZIP)
```bash
cd "$ROOT/lambdas"
npm ci
cd "$ROOT"

mkdir -p iac/lambda_artifacts
for fn in orders_create orders_get orders_update_status payments_create payments_webhook products_list notifications_worker inventory_worker; do
  (cd lambdas && zip -r "../iac/lambda_artifacts/${fn}.zip" "$fn" shared node_modules package.json package-lock.json >/dev/null)
done
ls -lh iac/lambda_artifacts/*.zip
```

## 7) Validate / Checkov / Plan / Apply con Ansible
```bash
cd "$ROOT"
export ANSIBLE_CONFIG="$ROOT/ansible/ansible.cfg"
export ANSIBLE_ROLES_PATH="$ROOT/ansible/roles"

BACKEND_ARGS=(
  -e "tf_backend_bucket=$TF_BACKEND_BUCKET"
  -e "tf_backend_key=envs/dev/terraform.tfstate"
  -e "tf_backend_region=$TF_BACKEND_REGION"
  -e "tf_backend_dynamodb_table=$TF_BACKEND_DDB_TABLE"
  -e "tf_backend_encrypt=true"
)

ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/validate.yml "${BACKEND_ARGS[@]}"
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/checkov.yml -e "repo_root=$ROOT" -e "checkov_soft_fail=true"
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/plan.yml "${BACKEND_ARGS[@]}"
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/apply.yml "${BACKEND_ARGS[@]}" -e "tf_auto_approve=true"
```

## 8) Cargar secreto real de pagos
```bash
cd "$ROOT"
PAYMENTS_SECRET_ARN="$(terraform -chdir=iac/envs/dev output -raw payments_secret_arn)"
aws secretsmanager put-secret-value \
  --secret-id "$PAYMENTS_SECRET_ARN" \
  --secret-string '{"stripe_secret_key":"...","paypal_client_id":"...","paypal_client_secret":"...","webhook_secret":"..."}'
```

## 9) Crear .env del frontend, build y publicar en S3
Este paso crea el archivo: `frontend/.env.production`

```bash
cd "$ROOT"
CF_DOMAIN="$(terraform -chdir=iac/envs/dev output -raw cloudfront_domain_name)"
FE_BUCKET="$(terraform -chdir=iac/envs/dev output -raw frontend_bucket_name)"
COGNITO_CLIENT_ID="$(terraform -chdir=iac/envs/dev output -raw cognito_app_client_id)"

cat > frontend/.env.production <<EOF
VITE_API_BASE_URL=https://${CF_DOMAIN}/api
VITE_AWS_REGION=${AWS_DEFAULT_REGION}
VITE_COGNITO_CLIENT_ID=${COGNITO_CLIENT_ID}
EOF

cd "$ROOT/frontend"
npm ci
npm run build
cd "$ROOT"

aws s3 sync frontend/dist "s3://${FE_BUCKET}" --delete
CF_ID="$(aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='${CF_DOMAIN}'].Id | [0]" --output text)"
aws cloudfront create-invalidation --distribution-id "$CF_ID" --paths "/*"
```

## 10) Ejecutar analisis Sonar del frontend
```bash
cd "$ROOT"
export SONAR_HOST_URL="http://localhost:9000"
export SONAR_PROJECT_KEY="proyecto-pepa-frontend"
export SONAR_TOKEN="TU_TOKEN_SONAR"

ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/sonar_frontend.yml
```

## 11) Smoke test
```bash
cd "$ROOT"
API_URL="$(terraform -chdir=iac/envs/dev output -raw api_invoke_url)"
curl -i -X POST "$API_URL/payments/webhook" -H "Content-Type: application/json" -d '{"event":"ping"}'
echo "Frontend URL: https://${CF_DOMAIN}"
```

## 12) Destroy (opcional)
```bash
cd "$ROOT"
ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/destroy.yml "${BACKEND_ARGS[@]}" -e "confirm_destroy=true" -e "tf_auto_approve=true"
```

