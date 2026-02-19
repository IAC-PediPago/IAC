import { useState } from "react";
import { apiFetch } from "../lib/api";
import { getSession, signOut } from "../lib/auth";

export default function ApiPlayground(props: { onLogout: () => void }) {
  const session = getSession();
  const [path, setPath] = useState("/products"); // ajusta según tus rutas reales
  const [method, setMethod] = useState<"GET" | "POST" | "PUT" | "DELETE">("GET");
  const [body, setBody] = useState(`{"ping":"pong"}`);
  const [result, setResult] = useState<string>("");

  const run = async () => {
    setResult("Ejecutando...");
    try {
      const res = await apiFetch(path, {
        method,
        body: method === "GET" || method === "DELETE" ? undefined : body,
      });

      setResult(
        JSON.stringify(
          {
            status: res.status,
            ok: res.ok,
            headers: res.headers,
            body: tryJson(res.bodyText),
          },
          null,
          2
        )
      );

      if (res.status === 401) {
        props.onLogout();
      }
    } catch (e: any) {
      setResult(e?.message || "Error");
      if ((e?.message || "").toLowerCase().includes("sesión")) {
        props.onLogout();
      }
    }
  };

  const logout = () => {
    signOut();
    props.onLogout();
  };

  return (
    <div style={{ maxWidth: 900, margin: "30px auto", fontFamily: "system-ui" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <h2>API Playground</h2>
        <button onClick={logout} style={{ padding: 10 }}>Cerrar sesión</button>
      </div>

      <div style={{ opacity: 0.85, fontSize: 13 }}>
        Token expira: {session ? new Date(session.expiresAt).toLocaleString() : "-"}
      </div>

      <div style={{ display: "grid", gap: 10, marginTop: 12 }}>
        <div style={{ display: "flex", gap: 10 }}>
          <select value={method} onChange={(e) => setMethod(e.target.value as any)} style={{ padding: 10 }}>
            <option>GET</option>
            <option>POST</option>
            <option>PUT</option>
            <option>DELETE</option>
          </select>

          <input
            value={path}
            onChange={(e) => setPath(e.target.value)}
            style={{ flex: 1, padding: 10 }}
            placeholder="/orders, /payments, /products ..."
          />

          <button onClick={run} style={{ padding: 10, minWidth: 120 }}>
            Ejecutar
          </button>
        </div>

        {(method === "POST" || method === "PUT") && (
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            rows={8}
            style={{ width: "100%", padding: 10, fontFamily: "ui-monospace, monospace" }}
          />
        )}

        <pre style={{ background: "#111", color: "#ddd", padding: 12, borderRadius: 8, overflow: "auto" }}>
          {result}
        </pre>

        <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
          <button onClick={() => { setMethod("GET"); setPath("/products"); }} style={{ padding: 10 }}>
            Preset: GET /products
          </button>
          <button onClick={() => { setMethod("POST"); setPath("/orders"); setBody(`{"items":[{"sku":"ABC","qty":1}]}`); }} style={{ padding: 10 }}>
            Preset: POST /orders
          </button>
        </div>
      </div>
    </div>
  );
}

function tryJson(text: string) {
  try { return JSON.parse(text); } catch { return text; }
}
