# Building & Distributing Shift

How to build Shift for yourself and package it for other Macs.

## Prerequisites

- macOS 11+
- A Swift 5.9+ toolchain — either full **Xcode** or just the standalone
  **Command Line Tools**: `xcode-select --install`

Everything below works with the Command Line Tools alone, except universal
(Intel + Apple Silicon) builds, which need full Xcode (see [Architecture](#architecture)).

---

## Develop locally

```bash
cd shift

swift build                 # compile (resolves the TOMLKit dependency)
swift run Shift            # launch the menu-bar agent (runs until you Quit)
swift run ShiftTests       # run the unit suite  → "65 passed, 0 failed"
swift run Shift --print-grid   # print computed grid frames, moves nothing
```

On first launch, grant **Accessibility** access (System Settings → Privacy &
Security → Accessibility). Shift lives in the menu bar; there's no Dock icon.

### Keeping the Accessibility grant across rebuilds

The plain debug binary is ad-hoc signed, so its signature changes on every
rebuild and macOS drops the Accessibility permission. To make the grant stick,
sign with a stable self-signed certificate and launch via the helper script:

1. **Keychain Access → Certificate Assistant → Create a Certificate…**
   Name `shift-dev`, Identity Type **Self Signed Root**, Certificate Type
   **Code Signing** → Create.
2. `export SHIFT_SIGN_ID="shift-dev"` (add it to `~/.zshrc` to persist).
3. Run with:
   ```bash
   ./scripts/dev-run.sh
   ```
   It builds, signs as a stable `app.shift.Shift` identity, stops any old
   instance, and launches. Grant Accessibility **once** and it survives rebuilds.

Debug log (DEBUG builds): `~/shift-debug.log`.

---

## Build a distributable app

```bash
./scripts/build-app.sh
```

Produces:

- `dist/Shift.app` — a release bundle. It's **self-contained (~300 KB)** because
  the TOMLKit dependency is statically linked; there are no extra files to ship.
- `dist/Shift.zip` — the artifact to send to other machines.

### Architecture

| Goal | Command | Needs |
|------|---------|-------|
| This Mac's architecture (Apple Silicon) | `./scripts/build-app.sh` | Command Line Tools |
| Universal (also runs on Intel Macs) | `ARCHS="arm64 x86_64" ./scripts/build-app.sh` | **Full Xcode** |

Multi-arch SwiftPM builds go through `xcbuild`, which ships only with full Xcode —
hence the native-only default. If every target Mac is Apple Silicon, the default
build is all you need.

### Signing

The app is **ad-hoc signed** — free, no Apple account needed. macOS Gatekeeper
treats it as coming from an unidentified developer, so recipients clear the
quarantine flag once (see install steps below).

---

## Install on another Mac

1. Unzip and drag `Shift.app` to `/Applications`.
2. If it refuses to open ("unidentified developer" or "damaged") — expected for
   ad-hoc builds — clear the quarantine flag:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Shift.app
   ```
3. Launch it and grant **Accessibility** when prompted. This is per-machine, so
   every Mac grants once.

---

## Releasing on GitHub

CI and releases run via GitHub Actions (not GoReleaser — that's Go-only and can't
build a SwiftPM macOS app):

- **`.github/workflows/ci.yml`** — builds and runs the test suite on every push to
  `main` and on pull requests.
- **`.github/workflows/release.yml`** — on a pushed tag, builds a **universal**
  `Shift.app` (GitHub's macOS runners have full Xcode), zips it, and publishes a
  GitHub Release with auto-generated notes.

Cut a release:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release artifact is ad-hoc signed; users clear the quarantine flag on first
launch (see install steps above).

---

## Troubleshooting

- **Hotkeys do nothing / menu shows "⚠ Grant Accessibility access".** The grant
  didn't take. Remove every stale **Shift** entry in System Settings →
  Accessibility, re-add the running one, then **quit and relaunch** — macOS often
  needs a restart of the app before `AXIsProcessTrusted()` flips to true.
- **next-display does nothing.** It only moves the window if you have a second
  monitor connected — otherwise there's nowhere to send it.
- **A position's shortcut doesn't fire.** Another app or the system may own that
  key combo. Check `~/shift-debug.log` for a `FAILED to register` line and pick a
  different key in `~/.config/shift/config.toml`.
