const { PutCommand } = require("@aws-sdk/lib-dynamodb");
const { PublishCommand } = require("@aws-sdk/client-sns");
const { GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const { ddb, sns, secrets } = require("../shared/aws");
const { created, ok, badRequest, serverError, parseJsonBody } = require("../shared/http");
const { requiredEnv } = require("../shared/validate");
const { newId } = require("../shared/ids");

exports.handler = async (event) => {
  try {
    const PAYMENTS_TABLE = requiredEnv("PAYMENTS_TABLE_NAME");
    const SNS_TOPIC_ARN = requiredEnv("SNS_TOPIC_ARN");
    const PAYMENTS_SECRET_ARN = requiredEnv("PAYMENTS_SECRET_ARN");

    const routeKey = event?.routeKey;
    const method = event?.requestContext?.http?.method;

    // POST /payments (JWT protegido por API GW, aquí solo lógica)
    if (routeKey === "POST /payments" || (method === "POST" && event?.rawPath?.endsWith("/payments"))) {
      const body = parseJsonBody(event);
      if (body === null) return badRequest("Invalid JSON body");

      const orderId = body.orderId;
      const amount = body.amount;

      if (!orderId) return badRequest("orderId is required");
      if (typeof amount !== "number" || amount <= 0) return badRequest("amount must be a positive number");

      // Lectura del secret para evidenciar permiso GetSecretValue
      const secretRes = await secrets.send(
        new GetSecretValueCommand({
          SecretId: PAYMENTS_SECRET_ARN,
        })
      );

      // No exponemos secretos, solo confirmamos que se pudo leer
      const secretLoaded = !!secretRes?.SecretString;

      const paymentId = newId("pay");
      const now = new Date().toISOString();

      const payment = {
        id: paymentId,
        orderId,
        amount,
        status: "CREATED",
        createdAt: now,
        updatedAt: now,
      };

      await ddb.send(
        new PutCommand({
          TableName: PAYMENTS_TABLE,
          Item: payment,
        })
      );

      await sns.send(
        new PublishCommand({
          TopicArn: SNS_TOPIC_ARN,
          Message: JSON.stringify({
            eventType: "PAYMENT_CREATED",
            paymentId,
            orderId,
            amount,
            createdAt: now,
          }),
        })
      );

      return created({ payment, secretLoaded });
    }

    // POST /payments/webhook (sin auth)
    if (routeKey === "POST /payments/webhook" || (method === "POST" && event?.rawPath?.endsWith("/payments/webhook"))) {
      const body = parseJsonBody(event);
      if (body === null) return badRequest("Invalid JSON body");

      // Simulación: solo logeamos para evidencia
      console.log("Webhook received:", body);

      return ok({ received: true });
    }

    return badRequest("Unsupported route");
  } catch (err) {
    console.error(err);
    return serverError("Unhandled error");
  }
};
