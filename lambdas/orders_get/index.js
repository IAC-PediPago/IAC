const { GetCommand } = require("@aws-sdk/lib-dynamodb");

const { ddb } = require("../shared/aws");
const { ok, badRequest, notFound, serverError } = require("../shared/http");
const { requiredEnv } = require("../shared/validate");

function orderKeys(orderId) {
  const key = `ORDER#${orderId}`;
  return { PK: key, SK: key };
}

exports.handler = async (event) => {
  try {
    const ORDERS_TABLE = requiredEnv("ORDERS_TABLE_NAME");

    const id = event?.pathParameters?.id;
    if (!id) return badRequest("Missing path param: id");

    const res = await ddb.send(
      new GetCommand({
        TableName: ORDERS_TABLE,
        Key: orderKeys(id),
      })
    );

    if (!res?.Item) return notFound("Order not found");
    return ok({ order: res.Item });
  } catch (err) {
    console.error("orders_get error:", err);
    return serverError(err?.message || "Unhandled error");
  }
};