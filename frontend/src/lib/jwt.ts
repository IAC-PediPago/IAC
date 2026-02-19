function base64UrlDecode(input: string) {
  const pad = "=".repeat((4 - (input.length % 4)) % 4);
  const base64 = (input + pad).replace(/-/g, "+").replace(/_/g, "/");
  const decoded = atob(base64);
  return decoded;
}

export function decodeJwtPayload<T = any>(token: string): T {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid JWT");
  const json = base64UrlDecode(parts[1]);
  return JSON.parse(json) as T;
}

export function getJwtExpiryMs(token: string): number {
  const payload = decodeJwtPayload<{ exp?: number }>(token);
  if (!payload.exp) return Date.now() + 5 * 60 * 1000;
  return payload.exp * 1000;
}

export function isExpired(expiresAt: number, skewMs = 30_000) {
  return Date.now() >= (expiresAt - skewMs);
}
