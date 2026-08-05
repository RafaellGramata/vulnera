# vulnera

A mobile vulnerability management platform built with Flutter and Firebase. Vulnera helps small teams track security assets, log and prioritize vulnerabilities, and monitor overall risk — with built-in tools to actively discover new findings, not just record ones you already know about.

## Overview

Most small teams and individual IT admins track vulnerabilities in spreadsheets or scattered notes — making it hard to prioritize risk, monitor remediation progress, or see an accurate security posture at a glance. Vulnera centralizes that workflow into a single mobile app: track assets (laptops, servers, network devices, web applications), log vulnerabilities against them, and let the app automatically calculate risk and keep your team in sync.

## Features

**Core**
- Firebase Authentication with persistent login sessions
- Full asset and vulnerability tracking (create, edit, delete), with cascade deletion to prevent orphaned records
- Dynamic, auto-recalculated risk scoring — an asset's risk score reflects the highest CVSS score among its currently open vulnerabilities, alongside an open-issue count
- Dashboard with severity-breakdown and per-asset risk charts

**CVE Integration**
- Live CVE lookup by exact ID or keyword search, pulling authoritative severity and CVSS data directly from the National Vulnerability Database (NVD)

**Team Collaboration**
- Role-based access control — Admin, Analyst, and Viewer roles, enforced directly in Firestore Security Rules (not just hidden in the UI), verified using Firebase's Rules Playground
- Vulnerability assignment, with in-app notifications when you're assigned a finding
- An append-only Activity Feed logging every meaningful action across the app
- In-app user management for Admins to promote or demote roles

**Reporting**
- PDF export of a full asset/vulnerability snapshot report
- A separate, date-range-filterable activity report

**Active Discovery**
- **Local Network Port Scanner** — scans devices on the same Wi-Fi network for open ports associated with commonly risky services (Telnet, SMB, RDP, etc.), automatically creating assets and vulnerabilities from what it finds
- **Website Security Scanner** — checks a given URL for HTTPS enforcement and key security headers (HSTS, Content-Security-Policy, X-Frame-Options, X-Content-Type-Options)

Both scanners follow the same pattern: detect → review findings → explicit user confirmation before anything is written to the database.

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase Authentication, Cloud Firestore
- **External API:** [National Vulnerability Database (NVD) API 2.0](https://nvd.nist.gov/developers)
- **PDF generation:** `pdf` / `printing`
- **Charts:** `fl_chart`

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A Firebase project (Authentication + Cloud Firestore enabled)
- A free [NVD API key](https://nvd.nist.gov/developers/request-an-api-key) (optional but recommended — avoids the stricter unauthenticated rate limit; note new keys can take a few hours to activate)

### Setup

1. Clone the repo:
   ```
   git clone https://github.com/your-username/vulnera.git
   cd vulnera
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Connect your own Firebase project:
   ```
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` for your project. (Note: this repo's committed `firebase_options.dart`, if present, points at the original development project — reconfigure to point at your own.)

4. Add your NVD API key. Create `lib/api_keys.dart` (this file is gitignored and will not be committed):
   ```dart
   const String nvdApiKey = 'YOUR_API_KEY_HERE';
   ```
   Leaving it as an empty string (`''`) still works, just with a stricter request rate limit.

5. Deploy the included Firestore Security Rules (`firestore.rules`) to your Firebase project via the Firebase console or CLI.

6. Run the app:
   ```
   flutter run
   ```

> **Note on the Local Network Port Scanner:** this feature scans devices on the same Wi-Fi network as the phone running the app. It cannot be tested on an Android emulator (emulators use an isolated virtual network) and will not find anything on networks with client isolation enabled (common on campus/enterprise Wi-Fi). Use a physical Android device on a standard home network to test it.

## Project Structure

```
lib/
  models/       # Data models (Asset, Vulnerability, AppUser, AppEvent, ...)
  services/     # Firestore/Auth/API logic (one service per concern)
  screens/      # UI screens
  main.dart
firestore.rules # Firestore Security Rules (reference copy — deploy via Firebase console/CLI)
```

## Security Notes

- Role-based access control is enforced server-side in `firestore.rules`, not just in the app's UI.
- New accounts default to the Viewer role (read-only), following the principle of least privilege; an Admin must explicitly promote a user before they can write data.
- API keys are kept out of version control via `lib/api_keys.dart` (gitignored).

## License

This project was built as a course project for CSIS 4280 at Douglas College.
