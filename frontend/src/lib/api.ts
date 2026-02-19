import { getSession, signOut } from "./auth";
import { isExpired } from "./jwt";

const baseUrl = import.meta.env.VITE_API_BASE_URL as string;

export type ApiResult = {
  status: number;
  ok: boolean;
  headers: Record<string, string>;
  bodyText: string;
};

export async function apiFetch(path: string, options?: RequestInit): Promise<ApiResult> {
  if (!baseUrl) throw new Error("Falta VITE_API_BASE_URL en .env");

  const session = getSession();
  if (!session) throw new Error("No hay sesión. Inicia sesión primero.");

  // Si está expirado, para demo lo más simple es cerrar sesión.
  // (Luego podemos implementar refresh token si lo necesitas)
  if (isExpired(session.expiresAt)) {
    signOut();
    throw new Error("Token expirado. Vuelve a iniciar sesión.");
  }

  const url = baseUrl.replace(/\/$/, "") + (path.startsWith("/") ? path : `/${path}`);

  const res = await fetch(url, {
    ...options,
    headers: {
      ...(options?.headers || {}),
      Authorization: `Bearer ${session.idToken}`,
      "Content-Type": "application/json",
    },
  });

  const headers: Record<string, string> = {};
  res.headers.forEach((v, k) => (headers[k] = v));

  const bodyText = await res.text();

  // Manejo típico 401
  if (res.status === 401) {
    // Por claridad en demo: limpiamos sesión
    signOut();
  }

  return {
    status: res.status,
    ok: res.ok,
    headers,
    bodyText,
  };
}
