const { GetCommand } = require("@aws-sdk/lib-dynamodb");
const { ddb } = require("../shared/aws");

function unwrapSnsFromSqsBody(sqsBody) {
  let outer;
  try {
    outer = typeof sqsBody === "string" ? JSON.parse(sqsBody) : sqsBody;
  } catch {
    return { raw: sqsBody };
  }

  if (outer && typeof outer === "object" && outer.Message) {
    try {
      return JSON.parse(outer.Message);
    } catch {
      return { message: outer.Message };
    }
  }

  return outer;
}

function orderKeys(orderId) {
  const key = `ORDER#${orderId}`;
  return { PK: key, SK: key };
}

function getEventType(payload) {
  return payload?.eventType || null;
}

function shouldProcess(eventType) {
  return eventType === "ORDER_CREATED";
}

function getOrderId(payload) {
  return payload?.orderId || null;
}

async function loadOrderIfPossible(ordersTableName, orderId) {
  if (!ordersTableName) return { order: null, reason: "ORDERS_TABLE_NAME not set" };

  const res = await ddb.send(
    new GetCommand({
      TableName: ordersTableName,
      Key: orderKeys(orderId),
    })
  );

  return { order: res?.Item || null, reason: res?.Item ? null : "Order not found" };
}

function logInventorySimulation(orderId, order) {
  const items = Array.isArray(order?.items) ? order.items : [];
  console.log(`[inventory] ORDER_CREATED recibido. orderId=${orderId}`);
  console.log(`[inventory] items (${items.length}):`, items);
  console.log(`[inventory] simulando reserva/descuento de stock para orderId=${orderId}`);
}

function logSkip(eventType, payload) {
  if (!eventType) {
    console.log("[skip] sin eventType. payload:", payload);
    return;
  }
  console.log(`[skip] eventType=${eventType}`);
}

async function processRecord(record, ordersTableName) {
  const payload = unwrapSnsFromSqsBody(record.body);

  const eventType = getEventType(payload);
  if (!eventType) {
    logSkip(eventType, payload);
    return;
  }

  if (!shouldProcess(eventType)) {
    logSkip(eventType, payload);
    return;
  }

  const orderId = getOrderId(payload);
  if (!orderId) throw new Error("ORDER_CREATED sin orderId");

  const { order, reason } = await loadOrderIfPossible(ordersTableName, orderId);

  if (ordersTableName && !order) {
    throw new Error(`No se pudo cargar la orden (${orderId}): ${reason}`);
  }

  if (!ordersTableName) {
    console.log(`[inventory] ORDER_CREATED recibido. orderId=${orderId}`);
    console.log("[inventory] ORDERS_TABLE_NAME no configurada; solo logging (demo).");
    return;
  }

  logInventorySimulation(orderId, order);
}

exports.handler = async (event) => {
  const records = event?.Records ?? [];
  console.log("inventory_worker records:", records.length);

  const ordersTableName = process.env.ORDERS_TABLE_NAME || null;
  const batchItemFailures = [];

  for (const record of records) {
    try {
      await processRecord(record, ordersTableName);
    } catch (err) {
      console.error(`[inventory] error messageId=${record.messageId}:`, err?.message || err);
      batchItemFailures.push({ itemIdentifier: record.messageId });
    }
  }

  return { batchItemFailures };
};