"use client";

import { useEffect } from "react";
import Link from "next/link";

export default function LandingPage() {
  useEffect(() => {
    async function init() {
      const { gsap } = await import("gsap");
      const { ScrollTrigger } = await import("gsap/ScrollTrigger");
      gsap.registerPlugin(ScrollTrigger);

      // ── GSAP hero ──────────────────────────────────────────────────────────
      const tl = gsap.timeline({ delay: 0.2 });
      tl.from(".hero-eyebrow", { y: 30, opacity: 0, duration: 0.7, ease: "power3.out" })
        .from(".hero-car",     { y: 60, opacity: 0, duration: 0.9, ease: "power4.out" }, "-=0.3")
        .from(".hero-dex",     { y: 60, opacity: 0, duration: 0.9, ease: "power4.out" }, "-=0.7")
        .from(".hero-sub",     { y: 24, opacity: 0, duration: 0.7, ease: "power3.out" }, "-=0.4")
        .from(".hero-cta",     { y: 20, opacity: 0, duration: 0.6, ease: "power2.out" }, "-=0.3")
        .from(".hero-scroll",  { opacity: 0, duration: 0.6 }, "-=0.1");

      // ── GSAP scroll reveals ─────────────────────────────────────────────────
      gsap.utils.toArray<Element>(".reveal").forEach((el) => {
        gsap.from(el, {
          y: 50, opacity: 0, duration: 0.8, ease: "power3.out",
          scrollTrigger: { trigger: el, start: "top 85%", toggleActions: "play none none none" },
        });
      });

      // ── GSAP counter ───────────────────────────────────────────────────────
      gsap.utils.toArray<Element>(".stat-num").forEach((el) => {
        const target = Number(el.getAttribute("data-target"));
        const obj = { val: 0 };
        gsap.to(obj, {
          val: target, duration: 2, ease: "power2.out",
          scrollTrigger: { trigger: el, start: "top 80%" },
          onUpdate: () => { el.textContent = Math.round(obj.val).toLocaleString("tr-TR"); },
        });
      });

      // ── GSAP features — GSAP pin (no empty scroll after last panel) ─────
      const featPanels  = gsap.utils.toArray<HTMLElement>(".feat-panel");
      const featDots    = gsap.utils.toArray<HTMLElement>(".feat-dot");
      const featSticky  = document.querySelector<HTMLElement>(".features-sticky");

      if (featSticky && featPanels.length) {
        const N = featPanels.length;
        let activeIdx = 0;

        gsap.set(featPanels, { opacity: 0, scale: 1 });
        gsap.set(featPanels[0], { opacity: 1 });
        featDots[0]?.classList.add("active");

        function goTo(idx: number) {
          if (idx === activeIdx) return;
          activeIdx = idx;
          gsap.killTweensOf(featPanels);
          gsap.set(featPanels, { opacity: 0, scale: 1, y: 0 });
          gsap.fromTo(
            featPanels[idx],
            { opacity: 0, scale: 0.97, y: 24 },
            { opacity: 1, scale: 1, y: 0, duration: 0.75, ease: "power2.out" },
          );
          featDots.forEach((d, i) => d.classList.toggle("active", i === idx));
        }

        // Pin the sticky container; progress 0→1 maps across (N-1)*100vh of scroll.
        // At progress=1 the pin immediately releases and the next section comes into view.
        ScrollTrigger.create({
          trigger:      featSticky,
          pin:          true,
          anticipatePin: 1,
          start:        "top top",
          end:          `+=${(N - 1) * 60}vh`,
          onUpdate: (self) => {
            const idx = Math.min(Math.floor(self.progress * N), N - 1);
            goTo(idx);
          },
        });
      }

      return () => { ScrollTrigger.getAll().forEach(t => t.kill()); };
    }

    const cleanup = init();
    return () => { cleanup.then((fn) => fn && fn()); };
  }, []);

  return (
    <>
      {/* Google Fonts */}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@700;900&family=Rajdhani:wght@300;400;600&family=JetBrains+Mono:wght@400&display=swap');

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
          --red:    #E8132A;
          --red-dim: #7a0a15;
          --white:  #F5F5F5;
          --dim:    #666;
          --bg:     #000000;
        }

        html { scroll-behavior: smooth; }
        body  { background: var(--bg); color: var(--white); overflow-x: hidden; }

        /* ── Nav ── */
        .nav {
          position: fixed; top: 0; left: 0; right: 0; z-index: 100;
          display: flex; align-items: center; justify-content: space-between;
          padding: 1.1rem 2.5rem;
          background: rgba(0,0,0,0.55);
          backdrop-filter: blur(10px);
          border-bottom: 1px solid rgba(255,255,255,0.06);
        }
        .nav-logo {
          font-family: 'Orbitron', sans-serif; font-size: 1rem; letter-spacing: .18em;
          color: var(--white); text-decoration: none; font-weight: 700;
        }
        .nav-logo span { color: var(--red); }
.nav-cta {
          font-family: 'Rajdhani', sans-serif; font-size: .9rem; font-weight: 700;
          letter-spacing: .08em; color: var(--white); text-decoration: none;
          background: var(--red); padding: .5rem 1.3rem;
          transition: opacity .2s; border-radius: 2px;
        }
        .nav-cta:hover { opacity: .85; }

        /* ── Hero ── */
        .hero {
          position: relative; height: 100vh; display: flex; flex-direction: column;
          align-items: center; justify-content: center; text-align: center;
          overflow: hidden;
        }
        .hero-bg {
          position: absolute; inset: 0;
          background-image: url('/hero_background.png');
          background-size: cover; background-position: center 60%;
          pointer-events: none;
        }
        .hero-overlay {
          position: absolute; inset: 0;
          background: linear-gradient(
            to bottom,
            rgba(0,0,0,0.55) 0%,
            rgba(0,0,0,0.35) 40%,
            rgba(0,0,0,0.65) 100%
          );
          pointer-events: none;
        }
        .hero-content { position: relative; z-index: 2; }
        .hero-eyebrow {
          font-family: 'JetBrains Mono', monospace; font-size: .72rem;
          letter-spacing: .35em; text-transform: uppercase; color: #e0e0e0;
          margin-bottom: 1.6rem;
        }
        .hero-title {
          font-family: 'Orbitron', sans-serif; font-size: clamp(5rem, 16vw, 13rem);
          font-weight: 900; line-height: .9; letter-spacing: -.01em;
          display: flex; align-items: baseline; gap: .08em;
        }
        .hero-car  { color: var(--white); display: block; }
        .hero-dex  { color: var(--red);   display: block; }
        .hero-sub {
          font-family: 'Rajdhani', sans-serif; font-size: clamp(1.1rem, 2.2vw, 1.4rem);
          font-weight: 400; letter-spacing: .12em;
          color: #bbb; margin: 1.8rem auto 0; max-width: 620px; text-align: center;
        }

        .hero-cta {
          display: inline-flex; align-items: center; gap: .6rem;
          margin-top: 3rem; padding: .85rem 2.4rem;
          border: 1px solid var(--red); background: transparent;
          font-family: 'Rajdhani', sans-serif; font-size: .9rem;
          letter-spacing: .2em; text-transform: uppercase; color: var(--white);
          text-decoration: none; transition: background .25s, color .25s;
          cursor: pointer;
        }
        .hero-cta:hover { background: var(--red); color: var(--white); }
        .hero-cta-arrow { font-size: 1.1rem; transition: transform .25s; }
        .hero-cta:hover .hero-cta-arrow { transform: translateX(4px); }

        .hero-scroll {
          position: absolute; bottom: 2.5rem; left: 50%; transform: translateX(-50%);
          display: flex; flex-direction: column; align-items: center; gap: .5rem;
          font-family: 'JetBrains Mono', monospace; font-size: .65rem;
          letter-spacing: .2em; color: var(--dim); text-transform: uppercase;
        }
        .hero-scroll-line {
          width: 1px; height: 40px;
          background: linear-gradient(to bottom, var(--dim), transparent);
          animation: scrollPulse 2s ease-in-out infinite;
        }
        @keyframes scrollPulse {
          0%, 100% { opacity: .3; transform: scaleY(1); }
          50%       { opacity: 1;  transform: scaleY(1.3); }
        }

        /* ── Features — Apple-style full-screen ── */
        .features-scroll {
          position: relative;
        }
        .features-sticky {
          height: 100vh;
          overflow: hidden;
          background: #000;
        }

        /* Paneller: tam ekran, içerik ortalı */
        .feat-panel {
          position: absolute; inset: 0;
          display: flex; flex-direction: column;
          align-items: center; justify-content: center;
          text-align: center;
          padding: 0 2rem;
          opacity: 0;
          will-change: opacity, transform;
        }

        /* Arkaplan dev numara */
        .feat-watermark {
          position: absolute;
          font-family: 'Orbitron', sans-serif;
          font-size: clamp(20rem, 48vw, 42rem);
          font-weight: 900; color: transparent;
          -webkit-text-stroke: 1px rgba(255,255,255,0.025);
          top: 50%; left: 50%;
          transform: translate(-50%, -50%);
          line-height: 1; pointer-events: none; user-select: none;
          z-index: 0;
        }

        /* İçerik — watermark'ın önünde */
        .feat-content {
          position: relative; z-index: 2;
          display: flex; flex-direction: column;
          align-items: center;
          max-width: 760px;
        }

        .feat-eyebrow {
          font-family: 'JetBrains Mono', monospace;
          font-size: .6rem; letter-spacing: .45em;
          text-transform: uppercase; color: #383838;
          display: block; margin-bottom: .75rem;
        }

        .feat-num {
          font-family: 'Orbitron', sans-serif;
          font-size: clamp(4rem, 9vw, 8rem);
          font-weight: 900; color: var(--red);
          line-height: 1; display: block;
          margin-bottom: 2rem;
          text-shadow:
            0 0 18px rgba(232,19,42,.9),
            0 0 45px rgba(232,19,42,.5),
            0 0 90px rgba(232,19,42,.2);
          letter-spacing: .06em;
        }

        .feat-name {
          font-family: 'Orbitron', sans-serif;
          font-size: clamp(2.4rem, 6vw, 5rem);
          font-weight: 900; color: var(--white);
          line-height: 1.08; letter-spacing: -.02em;
          margin-bottom: 1.8rem;
        }

        .feat-body {
          font-family: 'Rajdhani', sans-serif;
          font-size: clamp(1rem, 1.8vw, 1.3rem);
          font-weight: 300; color: #666; line-height: 1.9;
          max-width: 520px;
          margin-bottom: 2.5rem;
        }

        .feat-line {
          width: 40px; height: 2px; background: var(--red);
          box-shadow: 0 0 12px rgba(232,19,42,.7), 0 0 30px rgba(232,19,42,.3);
        }

        /* Alt progress çubuğu */
        .feat-dots {
          position: absolute; bottom: 3rem; left: 50%;
          transform: translateX(-50%);
          display: flex; gap: .5rem; z-index: 10;
        }
        .feat-dot {
          width: 6px; height: 6px; border-radius: 50%;
          background: #222;
          transition: all .45s cubic-bezier(.4,0,.2,1);
        }
        .feat-dot.active {
          width: 28px; border-radius: 3px;
          background: var(--red);
          box-shadow: 0 0 12px rgba(232,19,42,.9), 0 0 28px rgba(232,19,42,.35);
        }

        /* Üst eyebrow */
        .section-eyebrow {
          position: absolute; top: 2.5rem; left: 50%;
          transform: translateX(-50%);
          font-family: 'JetBrains Mono', monospace; font-size: .62rem;
          letter-spacing: .3em; text-transform: uppercase; color: #282828;
          z-index: 10; white-space: nowrap;
        }

        /* HUD köşe dekoru */
        .feat-corner {
          position: absolute;
          width: 24px; height: 24px;
          border-color: rgba(232,19,42,.2);
          border-style: solid;
          pointer-events: none; z-index: 10;
        }
        .feat-corner-tl { top: 2rem; left: 2rem; border-width: 1px 0 0 1px; }
        .feat-corner-tr { top: 2rem; right: 2rem; border-width: 1px 1px 0 0; }
        .feat-corner-bl { bottom: 2rem; left: 2rem; border-width: 0 0 1px 1px; }
        .feat-corner-br { bottom: 2rem; right: 2rem; border-width: 0 1px 1px 0; }

        /* HUD alt şeridi */
        .feat-hud {
          position: absolute; bottom: 2.2rem; right: 3rem;
          font-family: 'JetBrains Mono', monospace; font-size: .55rem;
          letter-spacing: .28em; color: #1e1e1e;
          display: flex; gap: 1.8rem; z-index: 10;
          text-transform: uppercase;
        }

        /* Scan-line overlay */
        .feat-scanlines {
          position: absolute; inset: 0; pointer-events: none; z-index: 5;
          background: repeating-linear-gradient(
            0deg,
            transparent, transparent 3px,
            rgba(0,0,0,0.035) 3px, rgba(0,0,0,0.035) 4px
          );
        }

        @media (max-width: 768px) {
          .feat-name { font-size: clamp(2rem, 8vw, 3rem); }
          .feat-watermark { font-size: 60vw; }
          .feat-hud { display: none; }
        }

        /* ── Stats ── */
        .stats {
          padding: 6rem 3rem;
          border-top: 1px solid #111; border-bottom: 1px solid #111;
          background: #030303;
        }
        .stats-inner {
          max-width: 1200px; margin: 0 auto;
          display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 3rem; text-align: center;
        }
        .stat-item {}
        .stat-num {
          font-family: 'Orbitron', sans-serif; font-size: clamp(2.5rem, 5vw, 4rem);
          font-weight: 900; color: var(--red); display: block;
          line-height: 1;
        }
        .stat-suffix {
          font-family: 'Orbitron', sans-serif; font-size: .7em; color: var(--red);
        }
        .stat-label {
          font-family: 'Rajdhani', sans-serif; font-size: .85rem;
          letter-spacing: .2em; text-transform: uppercase; color: var(--dim);
          margin-top: .6rem; display: block;
        }

        /* ── CTA section ── */
        .cta-section {
          padding: 10rem 3rem; text-align: center;
          position: relative; overflow: hidden;
        }
        .cta-bg-text {
          position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
          font-family: 'Orbitron', sans-serif; font-size: clamp(5rem, 20vw, 18rem);
          font-weight: 900; color: transparent;
          -webkit-text-stroke: 1px #111;
          white-space: nowrap; pointer-events: none; user-select: none;
          z-index: 0;
        }
        .cta-content { position: relative; z-index: 1; }
        .cta-title {
          font-family: 'Orbitron', sans-serif; font-size: clamp(1.4rem, 3vw, 2.2rem);
          font-weight: 700; color: var(--white); margin-bottom: 1rem;
        }
        .cta-sub {
          font-family: 'Rajdhani', sans-serif; font-size: 1.05rem;
          color: var(--dim); letter-spacing: .1em; margin-bottom: 3rem;
        }
        .cta-stores {
          display: flex; align-items: center; justify-content: center;
          gap: 1rem; flex-wrap: wrap;
        }
        .cta-store-btn {
          display: inline-flex; align-items: center; gap: .85rem;
          padding: .9rem 1.8rem;
          border: 1px solid #2a2a2a; background: #0a0a0a;
          color: var(--white); text-decoration: none;
          transition: border-color .25s, box-shadow .25s, background .25s;
          cursor: not-allowed; opacity: .85;
        }
        .cta-store-btn:hover {
          border-color: rgba(232,19,42,.5);
          box-shadow: 0 0 24px rgba(232,19,42,.12);
          background: #111;
        }
        .cta-store-icon { font-size: 1.6rem; line-height: 1; }
        .cta-store-text { text-align: left; }
        .cta-store-small {
          font-family: 'JetBrains Mono', monospace;
          font-size: .55rem; letter-spacing: .2em;
          text-transform: uppercase; color: #555;
          display: block; margin-bottom: .15rem;
        }
        .cta-store-name {
          font-family: 'Rajdhani', sans-serif;
          font-size: 1rem; font-weight: 600;
          letter-spacing: .05em; color: var(--white);
          display: block;
        }
        .cta-coming {
          display: block; margin-top: 1.5rem;
          font-family: 'JetBrains Mono', monospace;
          font-size: .6rem; letter-spacing: .3em;
          text-transform: uppercase; color: #333;
        }

        /* ── Footer ── */
        .footer {
          padding: 2rem 3rem;
          border-top: 1px solid #111;
          display: flex; align-items: center; justify-content: space-between;
          flex-wrap: wrap; gap: 1rem;
        }
        .footer-brand {
          font-family: 'Orbitron', sans-serif; font-size: .85rem;
          letter-spacing: .2em; color: var(--dim);
        }
        .footer-brand span { color: var(--red); }
        .footer-links { display: flex; gap: 2rem; }
        .footer-link {
          font-family: 'JetBrains Mono', monospace; font-size: .7rem;
          letter-spacing: .15em; text-transform: uppercase; color: var(--dim);
          text-decoration: none; transition: color .2s;
        }
        .footer-link:hover { color: var(--white); }

        /* ── Red glow line ── */
        .red-line {
          width: 60px; height: 3px; background: var(--red);
          margin: 0 auto 2rem;
        }

        @media (max-width: 640px) {
          .nav { padding: 1rem 1.5rem; }
          .stats { padding: 4rem 1.5rem; }
          .cta-section { padding: 6rem 1.5rem; }
          .footer { padding: 2rem 1.5rem; }
        }
      `}</style>

      {/* Nav */}
      <nav className="nav">
        <a href="/" className="nav-logo">CAR<span>DEX</span></a>
        <Link href="/login" className="nav-cta">Panele Gir</Link>
      </nav>

      {/* Hero */}
      <section className="hero">
        <div className="hero-bg" />
        <div className="hero-overlay" />
        <div className="hero-content">
          <p className="hero-eyebrow">araç veri yönetim sistemi</p>
          <div className="hero-title">
            <span className="hero-car">CAR</span>
            <span className="hero-dex">DEX</span>
          </div>
          <p className="hero-sub">Aracınızı tanıyın. Hatırlatmaları kaçırmayın. En yakın ustayı bulun.</p>
        </div>
        <div className="hero-scroll">
          <div className="hero-scroll-line" />
          <span>kaydır</span>
        </div>
      </section>

      {/* Features — Apple-style full-screen */}
      {(() => {
        const features = [
          { num: "01", title: "Araç Kaydı",          desc: "Plaka, marka, model, yıl ve km bilgilerinizi kaydedin. Tüm araçlarınız tek uygulamada." },
          { num: "02", title: "Akıllı Hatırlatmalar", desc: "Sigorta, kasko ve muayene bitiş tarihlerinizi girin. Süre dolmadan önce telefona push bildirim alın." },
          { num: "03", title: "En Yakın Usta",        desc: "GPS konumunuza göre anlaşmalı tamirhaneleri haritada görün. Mesafeye göre sıralanır." },
          { num: "04", title: "Sigorta Takibi",       desc: "Trafik sigortası ve kasko bitiş tarihlerinizi kaydedin. Yenileme zamanı geldiğinde uyarır." },
          { num: "05", title: "Servis Geçmişi",       desc: "Her bakım ve tamir kaydını tutun. Hangi işlem yapıldı, ne kadar ödendi — hepsi kayıt altında." },
          { num: "06", title: "Araç İstatistikleri",  desc: "Toplam km, servis maliyetleri ve yakıt tüketimi verilerini takip edin. Aracınızı daha iyi tanıyın." },
        ];
        return (
          <section className="features-scroll">
            <div className="features-sticky">
              <span className="section-eyebrow">// özellikler — kaydırarak keşfet</span>

              {/* Köşe HUD dekorları */}
              <div className="feat-corner feat-corner-tl" />
              <div className="feat-corner feat-corner-tr" />
              <div className="feat-corner feat-corner-bl" />
              <div className="feat-corner feat-corner-br" />

              {/* Scan-line overlay */}
              <div className="feat-scanlines" />

              {/* Paneller — tam ekran, ortalanmış */}
              {features.map((f) => (
                <div key={f.num} className="feat-panel">
                  <span className="feat-watermark">{f.num}</span>
                  <div className="feat-content">
                    <span className="feat-eyebrow">// özellik</span>
                    <span className="feat-num">{f.num}</span>
                    <h3 className="feat-name">{f.title}</h3>
                    <p className="feat-body">{f.desc}</p>
                    <div className="feat-line" />
                  </div>
                </div>
              ))}

              {/* Alt progress */}
              <div className="feat-dots">
                {features.map((f) => <div key={f.num} className="feat-dot" />)}
              </div>

              {/* HUD */}
              <div className="feat-hud">
                <span>SYS:ONLINE</span>
                <span>GPS:LOCKED</span>
                <span>VER:2.1.0</span>
              </div>
            </div>
          </section>
        );
      })()}

      {/* Stats */}
      <section className="stats">
        <div className="stats-inner">
          {[
            { target: 500, suffix: "+", label: "Anlaşmalı Tamirhane" },
            { target: 50,  suffix: "+", label: "Desteklenen Marka" },
            { target: 4,   suffix: "",  label: "Hatırlatma Türü" },
            { target: 7,   suffix: " gün", label: "Önceden Bildirim" },
          ].map((s) => (
            <div key={s.label} className="stat-item reveal">
              <span className="stat-num" data-target={s.target}>0</span>
              <span className="stat-suffix">{s.suffix}</span>
              <span className="stat-label">{s.label}</span>
            </div>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="cta-section">
        <div className="cta-bg-text">GET</div>
        <div className="cta-content">
          <div className="red-line reveal" />
          <h2 className="cta-title reveal">Uygulamayı İndirin</h2>
          <p className="cta-sub reveal">Aracınızı cebinizden yönetin.</p>
          <div className="cta-stores reveal">
            <a className="cta-store-btn">
              <span className="cta-store-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98l-.09.06c-.22.15-2.18 1.27-2.16 3.8.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.37 2.78M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                </svg>
              </span>
              <span className="cta-store-text">
                <span className="cta-store-small">App Store'dan İndir</span>
                <span className="cta-store-name">App Store</span>
              </span>
            </a>
            <a className="cta-store-btn">
              <span className="cta-store-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M3.18 23.76c.3.17.64.22.98.15l.11-.06 11.05-6.38-2.37-2.37-9.77 8.66zm-1.7-20.1C1.2 3.96 1 4.34 1 4.8v14.4c0 .46.2.84.48 1.14l.06.06 8.07-8.07v-.2L1.54 3.6l-.06.06zm18.54 7.72l-2.27-1.31-2.6 2.6 2.6 2.6 2.29-1.32c.65-.38.65-1.19-.02-1.57zm-16.56 9.6l10.33-5.97-2.37-2.37-7.96 8.34z"/>
                </svg>
              </span>
              <span className="cta-store-text">
                <span className="cta-store-small">Google Play'den İndir</span>
                <span className="cta-store-name">Google Play</span>
              </span>
            </a>
          </div>
          <span className="cta-coming reveal">// yakında kullanıma açılacak</span>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <span className="footer-brand">CAR<span>DEX</span> — Araç Veri Sistemi</span>
        <div className="footer-links">
          <Link href="/dashboard" className="footer-link">Panel</Link>
          <Link href="/api-docs" className="footer-link">API</Link>
          <a
            href="https://cardex.script-app.cloud/health"
            target="_blank"
            rel="noreferrer"
            className="footer-link"
          >
            Sağlık
          </a>
        </div>
      </footer>
    </>
  );
}
