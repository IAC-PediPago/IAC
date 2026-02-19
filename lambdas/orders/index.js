const { PutCommand, GetCommand, UpdateCommand } = require("@aws-sdk/lib-dynamodb");
const { PublishCommand } = require("@aws-sdk/client-sns");

const { ddb, sns } = require("../shared/aws");
const { created, ok, badRequest, notFound, serverError, parseJsonBody } = require("../shared/http");
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

    const method = event?.requestContext?.http?.method;
    const routeKey = event?.routeKey;
    const id = event?.pathParameters?.id;

    // POST /orders
    if (routeKey === "POST /orders" || (method === "POST" && event?.rawPath?.endsWith("/orders"))) {
      const body = parseJsonBody(event);
      if (body === null) return badRequest("Invalid JSON body");

      const customerName = body.customerName ?? null;
      const items = Array.isArray(body.items) ? body.items : [];
      const notes = body.notes ?? null;

      if (items.length === 0) return badRequest("items is required (array)");

      const orderId = newId("order");
      const now = new Date().toISOString();

      const keys = orderKeys(orderId);

      const order = {
        ...keys,
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
    }

    // GET /orders/{id}
    if (routeKey === "GET /orders/{id}" || (method === "GET" && id)) {
      if (!id) return badRequest("Missing path param: id");

      const keys = orderKeys(id);

      const res = await ddb.send(
        new GetCommand({
          TableName: ORDERS_TABLE,
          Key: keys,
        })
      );

      if (!res.Item) return notFound("Order not found");
      return ok({ order: res.Item });
    }

    // PUT /orders/{id}/status
    if (routeKey === "PUT /orders/{id}/status" || (method === "PUT" && id && event?.rawPath?.includes("/status"))) {
      if (!id) return badRequest("Missing path param: id");

      const body = parseJsonBody(event);
      if (body === null) return badRequest("Invalid JSON body");

      const status = body.status;
      const allowed = ["CREATED", "IN_PROGRESS", "PAID", "CANCELLED"];
      if (!status || !allowed.includes(status)) {
        return badRequest(`status must be one of: ${allowed.join(", ")}`);
      }

      const now = new Date().toISOString();

      const keys = orderKeys(id);

      const upd = await ddb.send(
        new UpdateCommand({
          TableName: ORDERS_TABLE,
          Key: keys,
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
    }

    return badRequest("Unsupported route");
  } catch (err) {
    console.error("Orders error:", err);
    return serverError(err?.message || "Unhandled error");
  }
};
