# Inventory App — Clarified Specification

> This document rewrites the original brief without adding any new features.  Ambiguous parts (especially around **state management**) are now explicit while the functional scope remains unchanged.

---

## 1 Purpose & Scope

A lightweight, offline‑capable Flutter application that supports yearly **stock‐taking (Inventur)** for small businesses. Core functions: scan item identifiers, gather optional prompt data, store results locally, and export them. Commercial add‑ons may enrich the experience but are not part of the free core.

---

## 2 Supported Platforms

| Target      | Notes                                             |
| ----------- | ------------------------------------------------- |
| **Android** | Target API 34. Publish via Google Play.           |
| **iOS**     | Target iOS 15+. Publish via TestFlight/App Store. |

UI should share a single widget tree (Material 3 widgets with adaptive padding). Platform‑specific visuals (Cupertino, custom nav bars, etc.) are **not required**.

---

## 3 Architecture Overview

### 3.1 Offline‑First & Pluggable Data Layer

* **Local persistence**: SQLite‑compatible database (Drift/Isar recommended). Must support basic SQL joins.
* **Repository interface (`IDataSource`)** abstracts CRUD. Two concrete implementations are expected:

  1. **LocalDbDataSource** (default, always available).
  2. **RestApiDataSource** (future, optional commercial add‑on).
* **Sync Strategy**: optimistic writes → local DB first, then optional background sync when connectivity is detected. Scanning must work for *hours* without network.
* **Threading**: long‑running DB/IO work is executed in background isolates with a progress stream so the UI remains responsive.

### 3.2 State Management (clarified)

State is managed with **Riverpod v3**:

| Layer                                                      | Riverpod Primitive      | Lifetime                                    |
| ---------------------------------------------------------- | ----------------------- | ------------------------------------------- |
| **Global app scope** (theme, upgrade status)               | `Provider`              | entire app session                          |
| **Repositories** (injected `IDataSource` impls)            | `Provider`              | entire app session                          |
| **Screen view‑models** (e.g., `ScanningVm`, `ProductDbVm`) | `StateNotifierProvider` | disposed when screen removed from nav stack |
| **Ephemeral dialog/overlay state**                         | `StateProvider`         | destroyed when overlay closed               |

**Why Riverpod?**  It allows compile‑time safety, clear dependency injection, and easy swapping between local and remote data sources by overriding providers in the root `ProviderScope`.

---

## 4 Data Model

| Entity           | Core Fields                                                                       | Notes                                         |
| ---------------- | --------------------------------------------------------------------------------- | --------------------------------------------- |
| `Product`        | `id` (primary key, string – barcode/EAN/QR), optional dynamic attributes (JSON)   | Holds stable data about an identifier.        |
| `Scan`           | `id` (uuid), `product_id` (FK), `timestamp`, `quantity` (int, default 1)          | One line per successful scan.                 |
| `PromptQuestion` | `id`, `label`, `input_type` (number\|text\|photo), `ask_mode` (once\|every\_scan) | Defined by user in **Stockkeeping Settings**. |
| `PromptAnswer`   | `id`, `scan_id` (FK), `question_id` (FK), `value` (string/blob)                   | Stores answers supplied after each scan.      |

All tables include `created_at` and `updated_at` for future audit/export needs.

---

## 5 Feature Set (Screens)

### 5.1 Home Screen

1. **Start Stock‑taking** → *Scanning Screen*
2. **Stock‑taking Settings**
3. **Product Database**
4. **Scan Results** (shows *\<total scans count>*)
5. **Upgrades Call‑out** (links to in‑app purchases)

### 5.2 Scanning Screen

* **Layout**: Split view with movable divider.

  * *Upper pane* — live camera feed with continuous QR/EAN scanning.
  * *Lower pane* — scrolling list of recent scans; newest entry briefly highlighted.
* **Controls**:

  * **Pause / Resume** toggle (disables camera stream without leaving screen).
* **Scanning flow**:

  1. Camera detects barcode → short beep/vibration.
  2. If *Quantity Prompt* enabled, ask for amount (numeric keypad).
  3. For each active **Prompt Question**, display appropriate input (text field, number, photo capture). Skip if `ask_mode = once` and product already has an answer.
  4. Persist to local DB; update running total in lower pane.

### 5.3 Stock‑taking Settings

* **Prompt Quantity** — on/off.
* **Additional Prompt Questions** — list with *Add*, *Edit*, *Delete*.

  * `input_type`: number | text | photo.
  * `ask_mode`: once per product OR every scan.
  * **Save Target**: *Product DB* **or** *Scan Result* (user chooses; UI explains difference).

### 5.4 Product Database

* Table listing all `Product` identifiers ever scanned.
* Search + sort (identifier, last scanned date).
* Detail view shows:

  * scan count & last seen
  * current attribute values (from Prompt Answers or manual edits)
  * chronological scan history (read‑only)
* User may create new fields (these become **Prompt Questions** automatically). Deleting a field removes it from both places.

### 5.5 Scan Results

* Chronological list of all `Scan` entries.
* Inline editing of quantity or prompt answers.
* **Export** button (see next section).

---

## 6 Data Export

* Manual trigger from **Scan Results** screen.
* Generates a **ZIP** containing:

  * `scans.csv` – flat table of all scans + basic prompt answers.
  * `products.csv` – current product attributes.
  * photo prompt files (if any) in `images/`.
* Share via platform share sheet (email, AirDrop, etc.).

---

## 7 Commercial Direction (Upgrades)

* AI image interpretation / alternate AI scanner mode.
* Product enrichment via EAN/GTIN APIs.
* Additional export formats.
* Future extension toward a light ERP module.

---

## 8 Non‑Functional Requirements

* **Performance**: <150 ms from scan detection to DB write.
* **Reliability**: retain data through app restarts and up to 24 h offline.
* **Accessibility**: haptic feedback when device is in silent mode; screen reader labels on all buttons.
* **Privacy**: all data stays on device unless user initiates export. No automatic cloud sync in free tier.

---

*Document version v0.2 — July 13 2025*
