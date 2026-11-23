# AutoPièces: diagrams and functions for the report

All diagrams are in `docs/diagrams/` as Mermaid source (`.mmd`, editable) and PNG (for Word / LaTeX).
Function names are the real ones from the code, so they match the source if the jury asks.

## 1. Sequence diagrams

| File | Scenario | Main functions to show |
|---|---|---|
| `seq1_scan_part` | Client scans a part and finds shops | `ScanScreen._capture()`, `PartScannerFactory.create()`, `PartScanner.identify(photoPaths)`, `_preprocess(path)`, `_run(input)`, `candidatesFromVotes(votes, total)`, `CandidatesScreen._confirm()`, `Repo.resultsForPart(partId)` |
| `seq2_reserve_pickup` | Reserve, confirm, pick up, review | `ResultsScreen._reserve(result)`, `Repo.reserve(result)`, `Repo.confirmReservation(r)`, `Repo.completeReservation(r)`, `Repo.addReview(...)`, `Repo.markReviewed(r)` |
| `seq3_login` | Login with role check | `LoginScreen._submit()`, `Validators.email/password`, `AuthService.login(role, email, password)`, `AuthException`, `HomeRouter` |
| `seq4_mechanic_job` | Mechanic job, invoice, report | `Repo.jobsWithStatus`, `acceptJob`, `startJob`, `addJobPhoto`, `finishJob`, `InvoiceScreen` + `saveInvoice` + `setJobPaid`, `addReport`, `updateReport` |

Other scenarios you can add with the same style:
- Sign up: `AuthService.signUp(...)`.
- Price alert: `showPriceAlertSheet` -> `Repo.setPriceAlert` -> `Repo.isAlertTriggered` -> Saved tab.
- Shop stock: `Repo.adjustStock`, `Repo.bulkPriceChange`, `Repo.removeStock`.
- Map: `MechanicsMapScreen._load()` -> `PlacesService.nearbyMechanics(center)`.

## 2. Class diagram (`class_diagram`)
Shows the data classes (`Part`, `Shop`, `StockItem`, `Reservation`, `Mechanic`, `RepairReport`, `Review`, `JobRequest`, `PriceAlert`),
the two singletons (`Repo` = data and rules, `AuthService` = login) and the scanner interface `PartScanner` with its three implementations
(`OnDevicePartScanner`, `RemotePartScanner`, `MockPartScanner`). Fields are shortened to stay readable.

## 3. Database diagram (`er_diagram`)
Be careful and say it honestly in the report:
- **Already in `php/database/schema.sql`:** `users`, `shops`, `parts`, `stock`, `reservations`, `mechanic_reports`.
- **Planned, not in the schema yet** (the app already uses them in memory): `job_requests`, `invoices`, `reviews`, `favorites`, `price_alerts`.
- `reservations.status` in the schema is `Pending / Confirmed / Cancelled`: add `Completed` to match the app.
- The app is currently on demo data (`BackendMode.mock`): the diagram describes the target MySQL database, not a connected one.

## 4. AI scanner in the report
- Model: YOLOv8s-cls on the Kaggle "car parts 50" dataset, 50 classes, test top-1 96.0 %, top-5 100 % (`ai_server/MODEL_RESULTS.md`).
- Runs inside the app (ONNX Runtime) or on the optional FastAPI server in `ai_server/`.
- Limits to state: only recognises the type of part, not compatibility with a car; 5 test photos per class.
