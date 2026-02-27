import { useState } from "react";
import { signIn } from "../lib/auth";

export default function Login(props: { onLoggedIn: () => void }) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const doLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setErr(null);
    setLoading(true);
    try {
      await signIn(username.trim(), password);
      props.onLoggedIn();
    } catch (e: any) {
      console.error("LOGIN_ERROR:", e);
      setErr(e?.name ? `${e.name}: ${e.message}` : (e?.message || "Error en login"));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: 420, margin: "40px auto", fontFamily: "system-ui" }}>
      <h2>PePa / PediPago - Login (Cognito)</h2>

      <form onSubmit={doLogin} style={{ display: "grid", gap: 10 }}>
        <label>
          Usuario
          <input
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            style={{ width: "100%", padding: 10 }}
            placeholder="usuario"
          />
        </label>

        <label>
          Password
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            style={{ width: "100%", padding: 10 }}
            placeholder="password"
          />
        </label>

        <button disabled={loading} style={{ padding: 12 }}>
          {loading ? "Ingresando..." : "Ingresar"}
        </button>

        {err && <div style={{ color: "crimson" }}>{err}</div>}
        <p style={{ opacity: 0.8, fontSize: 13 }}>
          Requiere que el App Client de Cognito permita USER_PASSWORD_AUTH.
        </p>
      </form>
    </div>
  );
}
