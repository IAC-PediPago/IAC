# Proyecto PePa — Plataforma serverless de Pedidos y Pagos (AWS) con IaC

Este repositorio contiene un proyecto académico del curso **Infraestructura como Código (IaC)**.  
El objetivo es diseñar e implementar una **plataforma serverless** tipo e-commerce para gestionar **pedidos, productos y pagos**, aplicando buenas prácticas de **automatización, seguridad, control de calidad y CI/CD**.

La infraestructura está construida en **AWS (us-east-1)** y se gestiona con:
- **Terraform** (Infraestructura como Código)
- **Jenkins** (CI/CD)
- **Ansible** (orquestación del pipeline y ejecución de Terraform)
- **Checkov** (revisión de seguridad IaC)
- **SonarQube** (calidad del frontend)

> Regla del proyecto: **no agregar servicios fuera del diagrama** salvo estricta necesidad técnica/seguridad/evaluación.

---

## Arquitectura (alto nivel)

Componentes principales:
- **Edge:** CloudFront + WAF (y Route53 opcional si se habilita dominio)
- **Autenticación:** Cognito (User Pool + App Client) y Authorizer JWT en API Gateway
- **API:** API Gateway HTTP API
- **Cómputo:** Lambdas por dominio (orders, payments, products + workers)
- **Datos:** DynamoDB (orders, payments, products)
- **Mensajería:** SNS Topic → SQS Queues + DLQ (workers consumen colas)
- **Secretos:** AWS Secrets Manager (configuración/secretos de pagos)
- **Observabilidad:** CloudWatch Logs (API access logs + log groups de Lambdas)

---

## Funcionalidades implementadas

- Infraestructura modular con Terraform (módulos por dominio).
- Backend serverless con Lambdas separadas por responsabilidad:
  - `orders_create`, `orders_get`, `orders_update_status`
  - `payments_create`, `payments_webhook`
  - `products_list`
  - workers: `notifications_worker`, `inventory_worker`
- API protegida con **JWT Authorizer** (Cognito).
- Mensajería completa: **SNS + SQS + DLQ + policies**.
- Logs de API y Lambdas centralizados en CloudWatch.
- Pipeline con validación, análisis de seguridad (Checkov) y calidad (SonarQube).

---

## Estructura del repositorio

- `iac/`
  - `envs/dev/` → Terraform root del entorno dev (state remoto)
  - `modules/` → módulos Terraform (api_auth, compute, data, messaging, edge, observability, secrets, frontend_hosting)
  - `lambda_artifacts/` → ZIPs generados para despliegue de Lambdas
- `lambdas/` → código Node.js de las Lambdas
- `ansible/`
  - `playbooks/` → `validate.yml`, `plan.yml`, `apply.yml`, `destroy.yml`, `checkov.yml`, `sonar_frontend.yml`
  - `roles/terraform/` → tareas reutilizables para ejecutar Terraform desde Jenkins
  - `inventories/dev/hosts.ini` → inventario local (localhost)
- `frontend/` → frontend mínimo para pruebas (Cognito + API)
- `docs/` → evidencias, diagramas y documentación del proyecto
- `tools/` → scripts auxiliares (ej: empaquetado de Lambdas)

---

## Requisitos

### Local
- Terraform
- AWS CLI (credenciales válidas)
- Node.js (para Lambdas)
- Docker (opcional si usas herramientas en contenedor)
- Ansible (si ejecutarás playbooks localmente)

### CI/CD
- Jenkins
- Credenciales AWS configuradas en Jenkins
- Token de SonarQube (si aplica)

---

## Entorno y estado remoto (Terraform)

Este proyecto usa **remote state** (S3) y locking (DynamoDB).

Ejemplo (dev):

```bash
terraform init -reconfigure -upgrade   -backend-config="bucket=pedidos-pagos-dev-tfstate-132681090057"   -backend-config="key=envs/dev/terraform.tfstate"   -backend-config="region=us-east-1"   -backend-config="dynamodb_table=pedidos-pagos-dev-tf-lock"   -backend-config="encrypt=true"
```

> Nota: según versión de Terraform/AWS provider pueden aparecer avisos de parámetros de backend; el flujo del proyecto se mantiene estable para el curso.

---

## Empaquetado de Lambdas (ZIP)

Los ZIPs se generan en `iac/lambda_artifacts/`.  
En Jenkins normalmente se empaquetan en el stage **Build Lambdas (ZIP)** del Jenkinsfile.

Para validar rápido que existen:
```bash
ls -lh iac/lambda_artifacts/*.zip
```

---

## Pipeline (Jenkins + Ansible)

Flujo del pipeline:

1. **Checkout**
2. **Sanity / Tools**
3. **Build Lambdas (ZIP)**
4. **Validate** (terraform init + fmt check + validate)
5. **Checkov** (seguridad IaC; puede correr en soft-fail)
6. **SonarQube** (calidad del frontend)
7. **Plan**
8. **Apply** (manual gate con confirmación)
9. **Destroy** (manual gate con confirmación)

Playbooks principales:
- `ansible/playbooks/validate.yml`
- `ansible/playbooks/plan.yml`
- `ansible/playbooks/apply.yml`
- `ansible/playbooks/destroy.yml`

---

## Comandos útiles para demo / presentación

### Ver outputs del despliegue
```bash
terraform output
```

### Listar Lambdas desplegadas (por prefijo)
```bash
aws lambda list-functions   --region us-east-1   --query "Functions[?starts_with(FunctionName, 'pedidos-pagos-dev-')].[FunctionName,Runtime,LastModified]"   --output table
```

### Ver logs (CloudWatch)

**PowerShell/CMD recomendado** (evita el problema de Git Bash con rutas que empiezan con `/aws/...`):

```powershell
aws logs tail "/aws/apigateway/pedidos-pagos-dev-http-api-access" --region us-east-1 --since 10m --follow
```

---

## Notas de calidad y seguridad

- **Checkov** analiza la infraestructura y genera reportes en formato JUnit para archivarlos en Jenkins.
- **SonarQube** analiza el frontend (configuración mínima para el curso).
- Se prioriza **least privilege** en IAM (por rol de Lambda y políticas específicas).
- Se centralizan logs para observabilidad básica del sistema.

---

## Cómo ejecutar (resumen)

### Ejecutar localmente (modo manual)
1. Empaquetar Lambdas (si corresponde).
2. `terraform init` con backend remoto.
3. `terraform validate`
4. `terraform plan -out tfplan`
5. `terraform apply tfplan`

### Ejecutar con Jenkins (modo CI/CD)
1. Lanzar job/pipeline
2. Revisar stages Validate/Checkov/Sonar/Plan
3. Aprobar Apply manualmente cuando corresponda

---

## Alcance de carga y operación (para evaluación)

> Los siguientes valores son supuestos razonables para un entorno académico/demostración (DEV).  
> Se pueden ajustar sin cambiar la arquitectura base.

- **¿Cuántos usuarios utilizarán el sistema?**  
  **10,000 – 50,000 usuarios/año** (usuarios únicos que compran o consultan productos).

- **¿Cuántos usuarios estarán conectados a la vez?**  
  **50 – 200 simultáneos** en operación normal.
  Picos de campaña: 300 – 800 simultáneos.

- **¿Cuáles son los periodos de actividad/carga del servicio?**  
  Días laborales: 12:00–14:00 y 18:00–23:00
  Fines de semana: 16:00–23:00
  Campañas / fechas especiales: picos (San Valentín, Día de la Madre, Navidad, etc.).

- **¿Cuánto tiempo debe estar disponible el servicio?**  
  Objetivo típico: **99.9% mensual** (≈ 43 min de caída máxima/mes).
  Si es crítico (ventas siempre activas): 99.95% (≈ 22 min/mes).

- **Backups y frecuencia**  
  - **Terraform state (S3):** versioning + encryption + bloqueo (DynamoDB).
    Frecuencia: cada cambio (el versionado guarda historial automáticamente).
- **DynamoDB:**
    PITR habilitado (recuperación continua) + backup on-demand antes de releases importantes.
    Recom: backup on-demand semanal (o antes de cada despliegue grande).
- **Logs CloudWatch:** retención típica real: 30–90 días (dev 14 días está bien).

- **¿Cuánta data se generará por año?**  
  Depende del tráfico y logging. Para un negocio pequeño/medio:
  **DynamoDB (datos):** 5 – 30 GB/año
  **Logs (CloudWatch):** 20 – 150 GB/año (si logueas mucho, sube rápido)

- **Tiempos de respuesta (objetivo)**  
  - **API (HTTP API + Lambda):** p95 < 400–700 ms en rutas típicas
  - **Checkout / pago:** p95 < 1.5–3 s (porque depende del proveedor externo)
