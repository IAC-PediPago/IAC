exports.handler = async (event) => {
  const records = event?.Records ?? [];
  console.log("inventory_worker records:", records.length);

  for (const r of records) {
    console.log("messageId:", r.messageId);
    console.log("body:", r.body);
  }

  return { ok: true, processed: records.length };
};
