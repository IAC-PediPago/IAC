const { ScanCommand } = require("@aws-sdk/lib-dynamodb");

const { ddb } = require("../shared/aws");
const { ok, serverError } = require("../shared/http");
const { requiredEnv } = require("../shared/validate");

exports.handler = async () => {
  try {
    const PRODUCTS_TABLE = requiredEnv("PRODUCTS_TABLE_NAME");

    const res = await ddb.send(
      new ScanCommand({
        TableName: PRODUCTS_TABLE,
        Limit: 50,
      })
    );

    const items = Array.isArray(res?.Items) ? res.Items : [];
    return ok({ products: items, count: items.length });
  } catch (err) {
    console.error("products_list error:", err);
    return serverError(err?.message || "Unhandled error");
  }
};