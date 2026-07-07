# Roadmap

An honest plan, not a promise. HealthWorker has **not yet been piloted with
real health workers** — everything after v0.1 depends on what a pilot teaches us.

## v0.1 — current

What exists and works in the app today:

- Patient records — offline SQLite; add, view, and track patients
- Symptom checker — 20 conditions classified per WHO IMCI, ranked matching,
  explicit referral criteria, WHO source cited for every condition
- Dosage calculator — 15 WHO essential medicines, weight-based dosing with
  floor-based WHO weight bands, per-drug maximum caps, and refusal to compute
  weight-based doses for age-based drugs (vitamin A, zinc)
- Vitals tracker — temperature / BP / weight with sanity-range validation
  and a temperature chart
- Facility directory — CHWs record their own local facilities
  (deliberately ships empty; we will not invent facility data)
- Onboarding, dark mode, fully offline, no accounts, no tracking

## v0.2 — next

- **Field pilot with a real CHW program** — the gating milestone; iterate on
  their feedback before adding anything else. If you run a program, open an issue.
- Localization: Swahili and Hindi first
- APK release via GitHub Releases (signed, reproducible steps documented)
- Accessibility pass: large text mode, checked against real low-end devices

## v1.0 — later

Only after a successful pilot:

- Optional, consented sync with supervisor reporting (design reviewed before
  any code — see CONTRIBUTING.md)
- FHIR export of patient records
- Region-specific data packs (national guideline variants of conditions/drugs)
- Play Store listing

## How versions ship

Any change to clinical content (`assets/data/` or dose logic) requires
WHO/BNFc citations and **two maintainer reviews**, per
[CONTRIBUTING.md](CONTRIBUTING.md). CI validates the medical data's safety
invariants (sources present, severe conditions always flag referral) on
every pull request. Safety fixes ship ahead of features, always.
