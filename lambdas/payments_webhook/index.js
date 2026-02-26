const { ok, badRequest, serverError, parseJsonBody } = require("../shared/http");

exports.handler = async (event) => {
  try {
    const body = parseJsonBody(event);
    if (body === null) return badRequest("Invalid JSON body");

    // Simulación: solo logueamos para evidencia
    console.log("payments_webhook received:", body);

    // A futuro: validar firma Stripe/PayPal y publicar evento PAYMENT_CONFIRMED
    return ok({ received: true });
  } catch (err) {
    console.error("payments_webhook error:", err);
    return serverError(err?.message || "Unhandled error");
  }
};