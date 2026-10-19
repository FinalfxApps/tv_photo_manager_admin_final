# FINAL FX TV Manager

Flutter web workspace for FINAL FX TV Photo Manager and Restaurant Studio.

## Included workspaces

- TV Photo Manager: media upload and gallery, media edit/delete, playlists, TV devices, schedules, and settings.
- Restaurant Studio: categories, menu items, offers, templates, TV groups, remote commands, QR menu, roles, and audit history.
- Responsive shell and back navigation for compact layouts.
- Shared high-contrast button, form, picker, and selected-state styling.

## Requirements

- Flutter SDK compatible with `pubspec.yaml` (`environment.sdk: ^3.13.4`).
- Firebase CLI authenticated to the intended Firebase project.
- Git installed and authenticated to the configured GitHub remote.

## Local development

```bash
flutter pub get
flutter analyze lib/main.dart lib/fx_master_restaurant_studio.dart
flutter run -d chrome
```

The analyzer may report existing deprecation/info/warning lints; a successful release build is the required compile gate:

```bash
flutter build web --release
```

## Safe install, checkpoint, preview, and production deploy

This package deliberately does not include `.git`, dated source backups, IDE metadata, build outputs, or Flutter cache files. The original uploaded source archive should be retained separately as the pre-cleanup snapshot.

Extract this package somewhere outside `~/Downloads/tv_photo_manager_admin`, then run from this package's project root:

```bash
bash scripts/finalize_release.sh
```

The script creates both a source backup and a Git history bundle, then merges the active source into the existing Downloads project **without deleting files missing from the clean package**. It fetches packages, runs analysis and any existing Dart tests, gates all remote actions on `flutter build web --release`, saves a clean source archive and the compiled web build, pushes the current Git branch, deploys a temporary Firebase preview, performs a basic HTTP/HTML smoke check, and only updates production when you type `DEPLOY` after manually testing the preview.

## Firebase and security notes

- `.firebaserc` maps the `admin` Hosting target to the existing `final-fx-tv` site in project `tv-app-31ad5`.
- `lib/firebase_options.dart` contains the FlutterFire client configuration needed by this client app; it is not a service-account private key.
- Firestore and Storage security rules were not included in the supplied archive. Review the rules in Firebase Console before production use; this package does not deploy or alter rules.
- A Hosting deploy only publishes the web client. It does not prove every Firebase operation works. Verify upload, delete, template selection, schedule save, TV remote commands, and the audit clear flow in the preview before production deploy.


## Automatic GitHub build check

`.github/workflows/flutter-web-ci.yml` runs on every push and pull request. It installs Flutter stable, resolves dependencies, checks active Dart entry points, builds the release website and keeps the compiled `build/web` output as a GitHub Actions artifact for 14 days. The workflow does not deploy Firebase; production still requires the guarded release script and manual approval.

## Release files kept on Desktop

The release script saves a timestamped source `.tar.gz`, Git history `.bundle`, clean source release `.zip`, compiled Web build `.zip`, release log, analyzer log and SHA-256 source manifest on the Desktop. It stops on errors and never automatically deletes the existing project or historical local files.
