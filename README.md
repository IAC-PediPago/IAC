 # Proyecto PePa: Plataforma  de Pedidos y Pagos (AWS)

Proyecto de **Infraestructura como Código (IaC)** desarrollado con Terraform, Jenkins y Ansible para una plataforma escalable.

 ## 1. Descripción del Proyecto
PePa es un sistema diseñado para gestionar el flujo completo de productos, órdenes y pagos, integrando proveedores externos como Stripe o PayPal. El principal desafío es soportar altos volúmenes de usuarios y transacciones simultáneas sin afectar la experiencia del usuario.

## 2. Problemática y Desafío
El sistema resuelve riesgos críticos de las plataformas transaccionales modernas:
* **Resiliencia**: Evita la pérdida o duplicación de pedidos ante fallos en servicios internos o externos.
* **Escalabilidad**: Prevención de saturación en horas pico mediante una arquitectura elástica que duplica su capacidad en menos de 5 minutos.
* **Seguridad**: Protección perimetral contra ataques y manejo seguro de tokens de autenticación.

### Componentes de Infraestructura
* **Edge & Perímetro**: Route 53, CloudFront y AWS WAF para bloquear ataques comunes y reducir la latencia.
* **API & Seguridad**: API Gateway protegido con Amazon Cognito (JWT) para asegurar endpoints privados.
* **Cómputo (Lambdas)**: Microservicios divididos por dominios (Pedidos, Pagos, Productos) y workers asíncronos para notificaciones e inventario.
* **Persistencia**: Tablas de DynamoDB con cifrado AES-256.
* **Mensajería**: SNS y SQS con Dead Letter Queues (DLQ) para desacoplamiento y manejo de errores.
