import {
  CognitoIdentityProviderClient,
  InitiateAuthCommand,
} from "@aws-sdk/client-cognito-identity-provider";
import { getJwtExpiryMs } from "./jwt";
import { saveAuth, clearAuth, loadAuth, type StoredAuth } from "./storage";

const region = import.meta.env.VITE_AWS_REGION as string;
const clientId = import.meta.env.VITE_COGNITO_CLIENT_ID as string;

if (!region || !clientId) {
  // Esto ayuda a fallar rápido si falta config
  console.warn("Missing VITE_AWS_REGION or VITE_COGNITO_CLIENT_ID");
}

const cognito = new CognitoIdentityProviderClient({ region });

export async function signIn(username: string, password: string): Promise<StoredAuth> {
  const cmd = new InitiateAuthCommand({
    AuthFlow: "USER_PASSWORD_AUTH",
    ClientId: clientId,
    AuthParameters: {
      USERNAME: username,
      PASSWORD: password,
    },
  });

  const res = await cognito.send(cmd);

  // Si Cognito pide challenge (MFA / NEW_PASSWORD_REQUIRED), lo reportamos claro:
  if (res.ChallengeName) {
    throw new Error(`Cognito Challenge requerido: ${res.ChallengeName}. (No implementado en este frontend de prueba)`);
  }

  const auth = res.AuthenticationResult;
  if (!auth?.IdToken || !auth?.AccessToken) {
    throw new Error("No se recibieron tokens (IdToken/AccessToken) desde Cognito.");
  }

  const expiresAt = getJwtExpiryMs(auth.IdToken);

  const stored: StoredAuth = {
    idToken: auth.IdToken,
    accessToken: auth.AccessToken,
    refreshToken: auth.RefreshToken,
    expiresAt,
  };

  saveAuth(stored);
  return stored;
}

export function signOut() {
  clearAuth();
}

export function getSession() {
  return loadAuth();
}
