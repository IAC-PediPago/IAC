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

    return ok({ items: res.Items ?? [] });
  } catch (err) {
    console.error(err);
    return serverError("Unhandled error");
  }
};
