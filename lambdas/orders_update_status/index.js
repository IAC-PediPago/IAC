const { UpdateCommand } = require("@aws-sdk/lib-dynamodb");
const { PublishCommand } = require("@aws-sdk/client-sns");

const { ddb, sns } = require("../shared/aws");
const { ok, badRequest, serverError, parseJsonBody } = require("../shared/http");
const { requiredEnv } = require("../shared/validate");

function orderKeys(orderId) {
  const key = `ORDER#${orderId}`;
  return { PK: key, SK: key };
}

exports.handler = async (event) => {
  try {
    const ORDERS_TABLE = requiredEnv("ORDERS_TABLE_NAME");
    const SNS_TOPIC_ARN = requiredEnv("SNS_TOPIC_ARN");

    const id = event?.pathParameters?.id;
    if (!id) return badRequest("Missing path param: id");

    const body = parseJsonBody(event);
    if (body === null) return badRequest("Invalid JSON body");

    const status = body.status;
    const allowed = ["CREATED", "IN_PROGRESS", "PAID", "CANCELLED"];
    if (!status || !allowed.includes(status)) {
      return badRequest(`status must be one of: ${allowed.join(", ")}`);
    }

    const now = new Date().toISOString();

    const upd = await ddb.send(
      new UpdateCommand({
        TableName: ORDERS_TABLE,
        Key: orderKeys(id),
        UpdateExpression: "SET #s = :s, updatedAt = :u",
        ExpressionAttributeNames: { "#s": "status" },
        ExpressionAttributeValues: { ":s": status, ":u": now },
        ReturnValues: "ALL_NEW",
      })
    );

    await sns.send(
      new PublishCommand({
        TopicArn: SNS_TOPIC_ARN,
        Message: JSON.stringify({
          eventType: "ORDER_STATUS_UPDATED",
          orderId: id,
          status,
          updatedAt: now,
        }),
      })
    );

    return ok({ order: upd.Attributes });
  } catch (err) {
    console.error("orders_update_status error:", err);
    return serverError(err?.message || "Unhandled error");
  }
};