function baseHeaders(extra = {}) {
  return {
    "content-type": "application/json",
    "access-control-allow-origin": "*",
    "access-control-allow-headers": "content-type,authorization",
    "access-control-allow-methods": "GET,POST,PUT,PATCH,DELETE,OPTIONS",
    ...extra,
  };
}

function json(statusCode, bodyObj, extraHeaders = {}) {
  return {
    statusCode,
    headers: baseHeaders(extraHeaders),
    body: JSON.stringify(bodyObj ?? {}),
  };
}

function ok(body = {}) {
  return json(200, body);
}

function created(body = {}) {
  return json(201, body);
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

function serverError(message = "Internal server error") {
  return json(500, { message });
}

function parseJsonBody(event) {
  if (!event || !event.body) return {};
  try {
    return typeof event.body === "string" ? JSON.parse(event.body) : event.body;
  } catch {
    return null; // inválido
  }
}

module.exports = {
  json,
  ok,
  created,
  badRequest,
  unauthorized,
  notFound,
  serverError,
  parseJsonBody,
};
