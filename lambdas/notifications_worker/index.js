exports.handler = async (event) => {
  // event.Records viene desde SQS
  const records = event?.Records ?? [];
  console.log("notifications_worker records:", records.length);

  for (const r of records) {
    console.log("messageId:", r.messageId);
    console.log("body:", r.body);
  }

  // Si no lanzas error, Lambda considera “OK” y SQS borra mensajes (por el mapping)
  return { ok: true, processed: records.length };
};
