# Contributing to HealthWorker

Thanks for helping build a tool for community health workers. Because this
app influences medical decisions, the bar for contributions is different
from a typical open-source project — please read this before opening a PR.

## The one rule that matters most

**Medical content must cite an authoritative source.** Every condition in
`assets/data/symptom_database.json` and every drug in
`assets/data/drug_reference.json` carries a `sources` array. A PR that adds
or changes clinical content without citing WHO / BNFc / national guideline
sources — page or section included — will not be merged, no matter how
correct it looks.

Accepted sources: WHO IMCI chart booklet, WHO Pocket Book of Hospital Care
for Children, WHO Model List of Essential Medicines (incl. Children), WHO
disease-specific guidelines, BNF for Children, national CHW guidelines
(cite country + year).

## Reporting a dosing or classification error

This is the most valuable contribution you can make. Open an issue titled
`[SAFETY]` with: the drug/condition, what the app shows, what the source
says, and a link/citation. Safety issues take priority over everything.

## Development setup

```bash
git clone https://github.com/chan-dra1/HEALTH-WORKER-ASSISTANT.git
cd HEALTH-WORKER-ASSISTANT
flutter create .     # regenerates platform folders (not committed)
flutter pub get
flutter test
flutter run
```

## Code guidelines

- Offline-first is non-negotiable. No feature may require connectivity to
  perform its core function.
- Dose calculations must be conservative: floor-based weight-band lookup,
  per-drug maximum caps, refusal (not guessing) when data is missing.
  See `lib/models/medication.dart` and its tests.
- New clinical logic needs tests (`test/`). Run `flutter test` before
  pushing.
- Keep the UI usable by someone with basic phone skills: large targets,
  minimal text entry, clear REFER warnings in red.

## What we will not accept

- Pre-loaded facility data (hospital names, phones, coordinates) that has
  not been verified on the ground. CHWs enter their own local facilities.
- Marketing claims in README/app about users, deployments, or accuracy
  that we cannot substantiate.
- Features that upload patient data anywhere, until a consented, secured
  sync design has been reviewed.

## Labels

- `good-first-issue` — UI polish, translations, tests
- `help-wanted` — larger features
- `safety` — clinical data corrections (highest priority)

## Pull request process

1. Fork, branch from `main`, make changes with tests.
2. `flutter test` and `flutter analyze` must pass.
3. Describe *why* — for clinical changes, quote the source text.
4. One maintainer review required; two for anything touching
   `assets/data/` or dose logic.
