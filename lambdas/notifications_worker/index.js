function unwrapSnsFromSqsBody(sqsBody) {
  let outer;
  try {
    outer = typeof sqsBody === "string" ? JSON.parse(sqsBody) : sqsBody;
  } catch {
    return { raw: sqsBody };
  }

  // Si viene de SNS:
  if (outer && typeof outer === "object" && outer.Message) {
    try {
      return JSON.parse(outer.Message);
    } catch {
      return { message: outer.Message };
    }
  }

  // Si no es SNS envelope, podría ser el evento directo
  return outer;
}

function summarizePayload(payload) {
  const eventType = payload?.eventType || "UNKNOWN";
  const orderId = payload?.orderId || null;
  const paymentId = payload?.paymentId || null;
  const status = payload?.status || null;

  return { eventType, orderId, paymentId, status };
}

function shouldNotify(eventType) {
  // Alineado con tu filtro actual:
  return ["ORDER_CREATED", "ORDER_STATUS_UPDATED", "PAYMENT_CREATED"].includes(eventType);
}

async function processNotification(payload) {
  const { eventType, orderId, paymentId, status } = summarizePayload(payload);

  if (!shouldNotify(eventType)) {
    console.log(`[skip] eventType=${eventType}`);
    return;
  }

  // Simulación de notificación (email/push/sms). Aquí solo evidenciamos lógica.
  if (eventType === "ORDER_CREATED") {
    console.log(`[notify] Nueva orden creada: orderId=${orderId}`);
    return;
  }

  if (eventType === "ORDER_STATUS_UPDATED") {
    console.log(`[notify] Orden actualizada: orderId=${orderId} status=${status}`);
    return;
  }

  if (eventType === "PAYMENT_CREATED") {
    console.log(`[notify] Pago registrado: paymentId=${paymentId} orderId=${orderId}`);
    return;
  }

  // fallback
  console.log(`[notify] Evento recibido: ${eventType}`);
}

exports.handler = async (event) => {
  const records = event?.Records ?? [];
  console.log("notifications_worker records:", records.length);

  const batchItemFailures = [];

  for (const r of records) {
    try {
      const payload = unwrapSnsFromSqsBody(r.body);

      // Si no hay eventType, no fallamos: solo lo registramos
      if (!payload?.eventType) {
        console.log("[skip] sin eventType. payload keys:", payload && typeof payload === "object" ? Object.keys(payload) : typeof payload);
        continue;
      }

      await processNotification(payload);
    } catch (err) {
      console.error(`[notifications] error messageId=${r.messageId}:`, err?.message || err);
      batchItemFailures.push({ itemIdentifier: r.messageId });
    }
  }

  return { batchItemFailures };
};