import { useState } from "react";
import Login from "./pages/Login";
import ApiPlayground from "./pages/ApiPlayground";
import { getSession } from "./lib/auth";

export default function App() {
  const [logged, setLogged] = useState<boolean>(() => !!getSession());

  return logged ? (
    <ApiPlayground onLogout={() => setLogged(false)} />
  ) : (
    <Login onLoggedIn={() => setLogged(true)} />
  );
}
