# Proyecto PePa — Plataforma serverless de Pedidos y Pagos (AWS) con IaC

Este repositorio contiene un proyecto académico basado en el caso **Mercado Libre – Pedidos y Pagos**, cuyo objetivo es diseñar e implementar una plataforma *serverless* capaz de soportar altos volúmenes de usuarios y transacciones, garantizando disponibilidad, rendimiento y seguridad.

La infraestructura está construida en **AWS (us-east-1)** y se gestiona con:
* **Terraform** (Infraestructura como Código)
* **Jenkins** (CI/CD)
* **Ansible** (Orquestación del pipeline y ejecución de Terraform)
* **Checkov** (Revisión de seguridad IaC)
* **SonarQube** (Calidad del código frontend)

> **Regla del proyecto:** No agregar servicios fuera del diagrama salvo estricta necesidad técnica, de seguridad o evaluación.



## Arquitectura 
* **Edge & Auth:** CloudFront + WAF + Cognito (JWT Authorizer).
* **API & Cómputo:** API Gateway HTTP + Lambdas (Node.js/Python).
* **Persistencia:** DynamoDB (Tablas para orders, payments, products).
* **Mensajería:** Patrón Fan-Out (SNS → SQS → Workers Lambdas).
* **Observabilidad:** CloudWatch Logs + Secrets Manager.

---

##  Script de Despliegue 

Ejecuta este bloque en tu terminal de **PowerShell** dentro de la raíz del proyecto para realizar el despliegue completo de un solo paso:

```powershell
# 1. Navegar al entorno de desarrollo
cd iac/envs/dev

# 2. Inicializar, Validar y Desplegar (Flujo Total)
terraform init -reconfigure -upgrade `
  -backend-config="bucket=pedidos-pagos-dev-tfstate-132681090057" `
  -backend-config="key=envs/dev/terraform.tfstate" `
  -backend-config="region=us-east-1" `
  -backend-config="dynamodb_table=pedidos-pagos-dev-tf-lock" `
  -backend-config="encrypt=true"; `
terraform fmt -recursive; `
terraform validate; `
terraform plan -out tfplan; `
terraform apply -auto-approve tfplan

# 3. Comandos de Verificación Inmediata
Write-Host "`n--- VERIFICACIÓN DE RECURSOS ---" -ForegroundColor Green
aws lambda list-functions --region us-east-1 --query "Functions[?starts_with(FunctionName, 'pedidos-pagos-dev-')].[FunctionName]" --output table
aws dynamodb list-tables --region us-east-1 --query "TableNames[?contains(@, 'pedidos-pagos-dev')]" --output table