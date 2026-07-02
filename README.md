# HealthWorker

**Offline decision-support app for Community Health Workers in low-resource settings.**

Works with zero internet. All data stays on the device. Free and open source (AGPL-3.0).

> ⚠️ **What this is and isn't:** HealthWorker supports trained health workers — it does not diagnose, is not a medical device, and never replaces clinical judgment or national guidelines. Severe-condition matches always show a red REFER warning. See the in-app "About & limits" screen.

## Status

Early development (v0.1). **Not yet piloted with real health workers.** The feature set below works in the app; field testing is the next milestone. If you run a CHW program and want to pilot it, open an issue.

## Features

- **Patient records** — offline SQLite; add, view, and track patients
- **Symptom checker** — 20 conditions classified per WHO IMCI; ranked matching with explicit referral criteria; every condition cites its WHO source in the UI
- **Dosage calculator** — 15 WHO essential medicines with weight-based dosing; floor-based WHO weight bands (never rounds a child up into a higher band); per-drug maximum caps; refuses to compute weight-based doses for age-based drugs (vitamin A, zinc); shows side effects, contraindications, and sources
- **Vitals tracker** — temperature / BP / weight per patient, with clinical sanity-range validation and a temperature chart
- **Facility directory** — the CHW records their own local hospitals, clinics and pharmacies (name, phone, directions). *Deliberately ships empty: we will not invent facility data.*
- Dark mode, works fully offline, no accounts, no tracking

## Where the medical data comes from

Every entry in `assets/data/` cites its source:

| Data | Source |
|---|---|
| Condition classifications | WHO IMCI Chart Booklet (2014) + WHO disease guidelines (malaria 3rd ed., dengue via WHO 2009 classification) |
| Drug doses | WHO Pocket Book of Hospital Care for Children (2nd ed., 2013, Annex 2), WHO EML for Children (2023), BNF for Children |

The data was compiled from these sources and then independently re-audited
(dose math, WHO band boundaries, contraindication gaps) before release.
Found an error? Open a `[SAFETY]` issue — top priority.

## Run it

Platform folders (`android/`, `ios/`) are generated, not committed:

```bash
git clone https://github.com/chan-dra1/HEALTH-WORKER-ASSISTANT.git
cd HEALTH-WORKER-ASSISTANT
flutter create .
flutter pub get
flutter test        # 20+ unit tests incl. dose-safety cases
flutter run
```

Requires Flutter 3.x, targets Android 8.0+.

## Project layout

```
lib/
  models/        patient, observation, medication, symptom_condition, facility
  services/      database_service (SQLite), symptom_engine, drug_reference
  screens/       home, symptom_checker, dosage_calculator, patient_tracker,
                 facilities, about
assets/data/     symptom_database.json, drug_reference.json  (WHO-cited)
test/            unit tests, including dose-safety regression tests
```

## Roadmap

- [x] Patient records, symptom checker, dosage calculator, vitals, facilities
- [ ] Pilot with a real CHW program and iterate on their feedback
- [ ] Localization (Swahili, Hindi first)
- [ ] Optional, consented sync for supervisor reporting
- [ ] Region-specific drug/condition packs

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: clinical content
requires WHO/BNFc citations, dose logic requires tests, and safety reports
beat features.

## License

AGPL-3.0 — see [LICENSE](LICENSE).
