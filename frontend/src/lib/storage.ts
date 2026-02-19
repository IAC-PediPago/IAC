const KEY = "pepa_auth";

export type StoredAuth = {
  idToken: string;
  accessToken: string;
  refreshToken?: string;
  expiresAt: number; // epoch ms
};

export function saveAuth(auth: StoredAuth) {
  localStorage.setItem(KEY, JSON.stringify(auth));
}

export function loadAuth(): StoredAuth | null {
  const raw = localStorage.getItem(KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as StoredAuth;
  } catch {
    return null;
  }
}

export function clearAuth() {
  localStorage.removeItem(KEY);
}
