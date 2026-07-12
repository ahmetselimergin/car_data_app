# Welcome / Onboarding Screen — Design

**Date:** 2026-07-11
**Scope:** Mobile app (`lib/`) only. No changes to auth logic, Supabase, or admin_desktop.

## Goal

1. Add an engaging, animated **first-launch welcome screen** that introduces the app before the user reaches login/register.
2. **Trim the verbose explanatory text** currently shown on the login and register screens.

## Flow & routing

A new `hasSeenWelcome` boolean is persisted in `shared_preferences` via an
`OnboardingController` singleton (mirrors `DistanceUnitController`).

`AppSessionGate._bootstrap()` branches after session sync:

| Condition | Screen |
| --- | --- |
| session exists | `HomeScreen` (unchanged) |
| no session, `!hasSeenWelcome` | **`WelcomeScreen`** |
| no session, `hasSeenWelcome` | `LoginScreen` (unchanged) |

`WelcomeScreen` buttons mark the flag `true`, then navigate:
- **Primary "Başla / Get started"** → `LoginScreen`
- **Secondary "Hesap oluştur / Create account"** → `RegisterScreen`

The screen therefore appears exactly once per install.

## WelcomeScreen layout (`lib/screens/welcome_screen.dart`)

Full-screen, `SafeArea`, theme-aware (light/dark, `AppTheme.primary` = `#1EA971`):
- **Hero illustration** — `ms_undraw` `UnDrawIllustration.electric_car` tinted with `AppTheme.primary` (dependency already present; no new asset).
- **Tagline** — short bold headline + one supporting line, all localized.
- **Primary pill button** — 54px, `BorderRadius.circular(32)` to match existing auth buttons → login.
- **Secondary text button** → register.
- No long paragraphs.

## Animation (`flutter_animate`, GSAP-like)

New dependency `flutter_animate` (pure Dart, small). Staggered entrance on first build:
- Illustration: `.fadeIn().scale()` ~500ms.
- Headline + subtitle: fade + slide-up, staggered ~150ms.
- Buttons: fade + slide-up last.
- Subtle continuous vertical float on the illustration for life.

## Copy trimming (all 3 locales: tr/en/es)

Shorten in `app_tr.arb`, `app_en.arb`, `app_es.arb`, then regenerate localizations:
- `loginSubtitle`: long Supabase paragraph → one short welcoming line.
- `registerSubtitle`: trimmed to one line.
- `loginFooterNote` / `registerFooterNote`: removed from the UI.
- New keys: `welcomeTitle`, `welcomeSubtitle`, `welcomeGetStarted`, `welcomeCreateAccount`.

Footer notes removed from `login_screen.dart` / `register_screen.dart` render trees.

## Files

- **New:** `lib/screens/welcome_screen.dart`, `lib/services/onboarding_controller.dart`
- **Edit:** `lib/app_session_gate.dart`, `lib/main.dart` (load flag), `pubspec.yaml`,
  `lib/l10n/app_{tr,en,es}.arb` (+ regenerated `app_localizations*.dart`),
  `lib/screens/login_screen.dart`, `lib/screens/register_screen.dart`.

## Verification

`flutter analyze` clean; `flutter gen-l10n` succeeds; manual: fresh install shows welcome once,
buttons route correctly, second launch skips to login.
