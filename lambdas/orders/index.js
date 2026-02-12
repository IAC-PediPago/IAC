exports.handler = async (event) => {
  return {
    statusCode: 200,
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      ok: true,
      service: process.env.SERVICE_NAME || "unknown",
      received: event,
    }),
  };
};
