# Plataforma serverless de pedidos y pagos (AWS) - IaC

Proyecto de curso de Infraestructura como Código (Terraform + Jenkins + Ansible) para una plataforma tipo e-commerce:
Edge (Route53/CloudFront/WAF), API Gateway + Cognito, Lambdas por dominio, DynamoDB, mensajería (SNS/SQS/DLQ),
pagos externos (Stripe/PayPal), observabilidad (CloudWatch) y secretos (Secrets Manager).

Regla: no agregar servicios fuera del diagrama salvo estricta necesidad técnica/seguridad/evaluación.

## Estructura

- iac/: Terraform (envs y módulos)
- ansible/: Playbooks para validate/plan/apply/destroy (ejecutados por Jenkins)
- docs/: documentación y evidencias
- frontend/: frontend mínimo (al final del índice)
