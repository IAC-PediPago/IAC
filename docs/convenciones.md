# Convenciones del proyecto

## Región y entorno
- Región única: us-east-1
- Entorno inicial: dev

## Naming estándar
- project_name: pedidos-pagos
- name_prefix: {project_name}-{env}
Ejemplo: pedidos-pagos-dev

## Tags (en todos los recursos posibles)
- Project = pedidos-pagos
- Environment = dev
- ManagedBy = terraform

## Convención por capa (referencial)
- S3 frontend: {name_prefix}-frontend
- CloudFront/WAF/API: {name_prefix}-edge / {name_prefix}-api
- DynamoDB: {name_prefix}-orders / {name_prefix}-payments / {name_prefix}-products
- SNS/SQS/DLQ: {name_prefix}-events / {name_prefix}-queue / {name_prefix}-dlq
- Lambdas: {name_prefix}-{dominio}-{accion}
- Secrets: {name_prefix}-payments-secrets

## Terraform
- env root: iac/envs/dev
- módulos: iac/modules/<capa>
- Nada de apply local (salvo bootstrap en el hito indicado). Luego todo desde Jenkins/Ansible.
