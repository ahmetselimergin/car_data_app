"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail]       = useState("");
  const [password, setPassword] = useState("");
  const [error, setError]       = useState("");
  const [loading, setLoading]   = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const res = await fetch("/api/auth/login", {
        method:  "POST",
        headers: { "Content-Type": "application/json" },
        body:    JSON.stringify({ email, password }),
      });
      if (res.ok) {
        router.push("/dashboard");
        router.refresh();
      } else {
        const j = await res.json() as { error?: string };
        setError(j.error ?? "Giriş başarısız");
      }
    } catch {
      setError("Bağlantı hatası");
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@700;900&family=Rajdhani:wght@300;400;600&family=JetBrains+Mono:wght@400&display=swap');

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
          --red:   #E8132A;
          --white: #F5F5F5;
          --dim:   #555;
          --bg:    #000;
          --card:  #0a0a0a;
        }

        body {
          background: var(--bg);
          color: var(--white);
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .login-wrap {
          width: 100%;
          max-width: 420px;
          padding: 1.5rem;
        }

        .login-logo {
          text-align: center;
          margin-bottom: 3rem;
        }
        .login-logo-text {
          font-family: 'Orbitron', sans-serif;
          font-size: 2rem;
          font-weight: 900;
          letter-spacing: .15em;
          color: var(--white);
        }
        .login-logo-text span { color: var(--red); }
        .login-logo-sub {
          font-family: 'JetBrains Mono', monospace;
          font-size: .65rem;
          letter-spacing: .3em;
          text-transform: uppercase;
          color: var(--dim);
          margin-top: .5rem;
        }

        .login-card {
          background: var(--card);
          border: 1px solid #1a1a1a;
          padding: 2.5rem;
          position: relative;
        }
        .login-card::before {
          content: '';
          position: absolute;
          top: 0; left: 0; right: 0;
          height: 2px;
          background: var(--red);
        }

        .login-title {
          font-family: 'Orbitron', sans-serif;
          font-size: .9rem;
          font-weight: 700;
          letter-spacing: .2em;
          text-transform: uppercase;
          color: var(--white);
          margin-bottom: 2rem;
        }

        .login-field {
          margin-bottom: 1.2rem;
        }
        .login-label {
          display: block;
          font-family: 'JetBrains Mono', monospace;
          font-size: .65rem;
          letter-spacing: .25em;
          text-transform: uppercase;
          color: var(--dim);
          margin-bottom: .5rem;
        }
        .login-input {
          width: 100%;
          background: #000;
          border: 1px solid #222;
          color: var(--white);
          padding: .75rem 1rem;
          font-family: 'JetBrains Mono', monospace;
          font-size: .9rem;
          letter-spacing: .1em;
          outline: none;
          transition: border-color .2s;
        }
        .login-input:focus {
          border-color: var(--red);
        }

        .login-error {
          background: rgba(232, 19, 42, 0.08);
          border: 1px solid rgba(232, 19, 42, 0.3);
          color: #ff4455;
          font-family: 'Rajdhani', sans-serif;
          font-size: .85rem;
          padding: .65rem .9rem;
          margin-bottom: 1.2rem;
          letter-spacing: .05em;
        }

        .login-btn {
          width: 100%;
          padding: .9rem;
          background: var(--red);
          border: none;
          color: var(--white);
          font-family: 'Orbitron', sans-serif;
          font-size: .75rem;
          font-weight: 700;
          letter-spacing: .25em;
          text-transform: uppercase;
          cursor: pointer;
          transition: opacity .2s, box-shadow .2s;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: .6rem;
        }
        .login-btn:hover:not(:disabled) {
          opacity: .9;
          box-shadow: 0 0 24px rgba(232, 19, 42, 0.35);
        }
        .login-btn:disabled {
          opacity: .5;
          cursor: not-allowed;
        }

        .login-back {
          text-align: center;
          margin-top: 1.5rem;
        }
        .login-back a {
          font-family: 'JetBrains Mono', monospace;
          font-size: .65rem;
          letter-spacing: .2em;
          text-transform: uppercase;
          color: var(--dim);
          text-decoration: none;
          transition: color .2s;
        }
        .login-back a:hover { color: var(--white); }

        /* Spinner */
        .spinner {
          width: 14px; height: 14px;
          border: 2px solid rgba(255,255,255,.3);
          border-top-color: #fff;
          border-radius: 50%;
          animation: spin .7s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* Animated grid background */
        .login-bg {
          position: fixed; inset: 0; z-index: -1; overflow: hidden;
        }
        .login-bg-grid {
          position: absolute; inset: -50%;
          background-image:
            linear-gradient(rgba(232,19,42,.04) 1px, transparent 1px),
            linear-gradient(90deg, rgba(232,19,42,.04) 1px, transparent 1px);
          background-size: 60px 60px;
          animation: gridMove 20s linear infinite;
        }
        @keyframes gridMove {
          0%   { transform: translate(0,0); }
          100% { transform: translate(60px,60px); }
        }
        .login-bg-vignette {
          position: absolute; inset: 0;
          background: radial-gradient(ellipse at center, transparent 20%, #000 80%);
        }
      `}</style>

      {/* Animated background */}
      <div className="login-bg">
        <div className="login-bg-grid" />
        <div className="login-bg-vignette" />
      </div>

      <div className="login-wrap">
        <div className="login-logo">
          <div className="login-logo-text">CAR<span>DEX</span></div>
          <div className="login-logo-sub">// yönetim paneli</div>
        </div>

        <div className="login-card">
          <p className="login-title">Giriş Yap</p>

          <form onSubmit={handleSubmit}>
            <div className="login-field">
              <label htmlFor="email" className="login-label">E-posta</label>
              <input
                id="email"
                type="email"
                className="login-input"
                placeholder="admin@cardex.app"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoFocus
                autoComplete="email"
                required
              />
            </div>
            <div className="login-field">
              <label htmlFor="password" className="login-label">Şifre</label>
              <input
                id="password"
                type="password"
                className="login-input"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
                required
              />
            </div>

            {error ? <div className="login-error">{error}</div> : null}

            <button type="submit" className="login-btn" disabled={loading}>
              {loading ? <><div className="spinner" /> Doğrulanıyor...</> : "Giriş Yap →"}
            </button>
          </form>
        </div>

        <div className="login-back">
          <a href="/">← Ana sayfaya dön</a>
        </div>
      </div>
    </>
  );
}
