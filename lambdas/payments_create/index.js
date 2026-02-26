const { PutCommand } = require("@aws-sdk/lib-dynamodb");
const { PublishCommand } = require("@aws-sdk/client-sns");
const { GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const { ddb, sns, secrets } = require("../shared/aws");
const { created, badRequest, serverError, parseJsonBody } = require("../shared/http");
const { requiredEnv } = require("../shared/validate");
const { newId } = require("../shared/ids");

exports.handler = async (event) => {
  try {
    const PAYMENTS_TABLE = requiredEnv("PAYMENTS_TABLE_NAME");
    const SNS_TOPIC_ARN = requiredEnv("SNS_TOPIC_ARN");
    const PAYMENTS_SECRET_ARN = requiredEnv("PAYMENTS_SECRET_ARN");

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

    // No exponemos secretos; solo confirmamos que se pudo leer
    const secretLoaded = !!secretRes?.SecretString;

    const paymentId = newId("pay");
    const now = new Date().toISOString();

    // Single-table style (recomendado): PK/SK
    const key = `PAYMENT#${paymentId}`;
    const payment = {
      PK: key,
      SK: key,
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
  } catch (err) {
    console.error("payments_create error:", err);
    return serverError(err?.message || "Unhandled error");
  }
};