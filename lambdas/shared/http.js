function json(statusCode, bodyObj) {
  return {
    statusCode,
    headers: {
      "content-type": "application/json",
      "access-control-allow-origin": "*"
    },
    body: JSON.stringify(bodyObj ?? {})
  };
}

function badRequest(message, extra = {}) {
  return json(400, { message, ...extra });
}

function unauthorized(message = "Unauthorized") {
  return json(401, { message });
}

function notFound(message = "Not found") {
  return json(404, { message });
}

module.exports = { json, badRequest, unauthorized, notFound };
