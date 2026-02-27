const { PutCommand } = require("@aws-sdk/lib-dynamodb");
const { PublishCommand } = require("@aws-sdk/client-sns");

const { ddb, sns } = require("../shared/aws");
const { created, badRequest, serverError, parseJsonBody } = require("../shared/http");
const { requiredEnv } = require("../shared/validate");
const { newId } = require("../shared/ids");

function orderKeys(orderId) {
  // Single-table style: PK/SK
  const key = `ORDER#${orderId}`;
  return { PK: key, SK: key };
}

exports.handler = async (event) => {
  try {
    const ORDERS_TABLE = requiredEnv("ORDERS_TABLE_NAME");
    const SNS_TOPIC_ARN = requiredEnv("SNS_TOPIC_ARN");

    const body = parseJsonBody(event);
    if (body === null) return badRequest("Invalid JSON body");

    const customerName = body.customerName ?? null;
    const items = Array.isArray(body.items) ? body.items : [];
    const notes = body.notes ?? null;

    if (items.length === 0) return badRequest("items is required (array)");

    const orderId = newId("order");
    const now = new Date().toISOString();

    const order = {
      ...orderKeys(orderId),
      id: orderId,
      status: "CREATED",
      customerName,
      items,
      notes,
      createdAt: now,
      updatedAt: now,
    };

    await ddb.send(
      new PutCommand({
        TableName: ORDERS_TABLE,
        Item: order,
      })
    );

    await sns.send(
      new PublishCommand({
        TopicArn: SNS_TOPIC_ARN,
        Message: JSON.stringify({
          eventType: "ORDER_CREATED",
          orderId,
          createdAt: now,
        }),
      })
    );

    return created({ order });
  } catch (err) {
    console.error("orders_create error:", err);
    return serverError(err?.message || "Unhandled error");
  }
};