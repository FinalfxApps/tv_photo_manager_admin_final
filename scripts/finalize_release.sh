#!/usr/bin/env bash
# FINAL FX TV Manager — guarded build, GitHub checkpoint, Firebase preview and production release.
# No destructive rsync is used. Existing project is backed up before active files are updated.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="${FINAL_FX_PROJECT_DEST:-$HOME/Downloads/tv_photo_manager_admin}"
PROJECT_ID="tv-app-31ad5"
HOSTING_TARGET="admin"
LIVE_URL="https://final-fx-tv.web.app/"
STAMP="$(date +%Y%m%d-%H%M%S)"
ARTIFACT_DIR="$HOME/Desktop/FINAL_FX_RELEASE_${STAMP}"
LOG="$ARTIFACT_DIR/release.log"
SOURCE_BACKUP="$HOME/Desktop/FINAL_FX_TV_Manager_SOURCE_BACKUP_${STAMP}.tar.gz"
GIT_BUNDLE="$HOME/Desktop/FINAL_FX_TV_Manager_GIT_HISTORY_${STAMP}.bundle"

mkdir -p "$ARTIFACT_DIR"
exec > >(tee -a "$LOG") 2>&1

fail() { printf '\nERROR: %s\n' "$1" >&2; printf 'Release log: %s\n' "$LOG" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"; }

printf '\n============================================================\n'
printf 'FINAL FX TV MANAGER GUARDED RELEASE\n'
printf 'Started: %s\n' "$(date)"
printf 'Package: %s\nDestination: %s\n' "$PACKAGE_ROOT" "$DEST"
printf 'Release logs/artifacts: %s\n' "$ARTIFACT_DIR"
printf '============================================================\n'

# Validate package before touching the working project.
for f in pubspec.yaml pubspec.lock firebase.json .firebaserc .gitignore \
  lib/main.dart lib/fx_master_restaurant_studio.dart lib/firebase_options.dart \
  lib/auth_gate.dart lib/fx_admin_role_ui.dart lib/tenant_scope.dart web/index.html; do
  [[ -s "$PACKAGE_ROOT/$f" ]] || fail "Package is missing required file: $f"
done
[[ -f "$DEST/.git/config" ]] || fail "Existing project Git repository not found at $DEST. No files were changed."
need_cmd rsync; need_cmd flutter; need_cmd dart; need_cmd git; need_cmd firebase; need_cmd tar; need_cmd zip; need_cmd curl

# Guard the intended repository and keep the current branch.
REMOTE_URL="$(git -C "$DEST" remote get-url origin 2>/dev/null || true)"
REMOTE_CANON="$(printf '%s' "$REMOTE_URL" | tr '[:upper:]' '[:lower:]' | sed -E 's#^(https://github.com/|ssh://git@github.com/|git@github.com:)##; s#\.git$##')"
[[ "$REMOTE_CANON" == "finalfxapps/tv_photo_manager_admin_final" ]] || fail "origin is not the expected GitHub repository. Current origin: ${REMOTE_URL:-<missing>}. No files were changed."
BRANCH="$(git -C "$DEST" branch --show-current)"
[[ -n "$BRANCH" ]] || fail "Git is in detached-HEAD state; switch to a branch first."
printf '\nExpected GitHub remote confirmed: %s\nBranch to preserve/push: %s\n' "$REMOTE_URL" "$BRANCH"

# Verify Firebase project/hosting target in the package configuration.
python3 - "$PACKAGE_ROOT/firebase.json" "$PACKAGE_ROOT/.firebaserc" "$PROJECT_ID" "$HOSTING_TARGET" <<'PYCFG'
import json, sys
firebase_json, firebaserc, project_id, target = sys.argv[1:]
with open(firebase_json, encoding='utf-8') as f: cfg = json.load(f)
with open(firebaserc, encoding='utf-8') as f: rc = json.load(f)
hosts = cfg.get('hosting', [])
if isinstance(hosts, dict): hosts = [hosts]
if not any(h.get('target') == target and h.get('public') == 'build/web' for h in hosts):
    raise SystemExit(f'ERROR: firebase.json must map hosting target {target!r} to build/web')
targets = rc.get('targets', {}).get(project_id, {}).get('hosting', {}).get(target, [])
if 'final-fx-tv' not in targets:
    raise SystemExit(f'ERROR: .firebaserc does not map {project_id}/{target} to final-fx-tv')
print(f'Firebase config verified: project={project_id}, target={target}, site=final-fx-tv')
PYCFG

# Keep a source snapshot and Git history bundle before any merge or code replacement.
printf '\n[1/9] Backing up source and Git history...\n'
tar -czf "$SOURCE_BACKUP" \
  --exclude='tv_photo_manager_admin/.git' \
  --exclude='tv_photo_manager_admin/build' \
  --exclude='tv_photo_manager_admin/.dart_tool' \
  --exclude='tv_photo_manager_admin/.firebase' \
  --exclude='tv_photo_manager_admin/node_modules' \
  -C "$(dirname "$DEST")" "$(basename "$DEST")"
printf 'Source backup: %s\n' "$SOURCE_BACKUP"
git -C "$DEST" bundle create "$GIT_BUNDLE" --all
git -C "$DEST" bundle verify "$GIT_BUNDLE" | tee "$ARTIFACT_DIR/git-bundle-verify.log"
printf 'Git history backup: %s\n' "$GIT_BUNDLE"
git -C "$DEST" status --short | tee "$ARTIFACT_DIR/pre-sync-git-status.txt"

# Merge the current package into the existing repository. Intentionally do NOT use --delete:
# files not included in this clean package are preserved rather than silently removed.
printf '\n[2/9] Syncing active project files (preserving other files and .git)...\n'
if [[ "$PACKAGE_ROOT" != "$DEST" ]]; then
  rsync -a \
    --exclude='.git/' --exclude='build/' --exclude='.dart_tool/' \
    --exclude='.firebase/' --exclude='node_modules/' \
    "$PACKAGE_ROOT/" "$DEST/"
fi
cd "$DEST"

# Refuse to push obvious private-key/credential files. Firebase client configuration is allowed.
SECRET_LIST="$ARTIFACT_DIR/potential-secret-files.txt"
find . \
  -path './.git' -prune -o -path './build' -prune -o -path './.dart_tool' -prune -o \
  -path './.firebase' -prune -o -path './.idea' -prune -o -path './backup' -prune -o -path './lib/backup' -prune -o \
  -type f \( -name 'serviceAccountKey.json' -o -name 'service-account*.json' \
    -o -name 'firebase-adminsdk*.json' -o -name '*.pem' -o -name '*.p12' -o -name '*.pfx' \
    -o -name '.env' -o \( -name '.env.*' ! -name '.env.example' \) \) -print > "$SECRET_LIST"
if [[ -s "$SECRET_LIST" ]]; then
  cat "$SECRET_LIST"
  fail "Possible secret/credential files found. Review them and ensure they are excluded before GitHub push. No push/deploy has occurred."
fi

printf '\n[3/9] Resolving Flutter dependencies...\n'
flutter pub get

printf '\n[4/9] Running analyzer and checking for actual Dart errors...\n'
ANALYZE_LOG="$ARTIFACT_DIR/flutter-analyze.log"
set +e
flutter analyze lib/main.dart lib/fx_master_restaurant_studio.dart 2>&1 | tee "$ANALYZE_LOG"
ANALYZE_STATUS=${PIPESTATUS[0]}
set -e
if grep -E 'error[[:space:]]*[•-]|: Error:|Error when compiling|Could not compile' "$ANALYZE_LOG" >/dev/null; then
  fail "Dart analyzer found errors. Fix them before saving or deploying. See $ANALYZE_LOG"
fi
if [[ "$ANALYZE_STATUS" -ne 0 ]]; then
  printf 'Analyzer exit=%s with no compiler-error markers; warnings/info are recorded. Release build remains the mandatory compile gate.\n' "$ANALYZE_STATUS"
fi

printf '\n[5/9] Running tests if a test suite exists...\n'
if [[ -d test ]] && find test -type f -name '*_test.dart' -print -quit | grep -q .; then
  flutter test
else
  printf 'No Dart test files were found; test phase skipped and recorded.\n'
fi

printf '\n[6/9] Building Flutter Web release (required gate)...\n'
flutter build web --release
[[ -s build/web/index.html ]] || fail "Web build did not produce build/web/index.html. No GitHub push or Firebase deploy occurred."
WEB_FILE_COUNT="$(find build/web -type f | wc -l | tr -d ' ')"
[[ "$WEB_FILE_COUNT" -gt 5 ]] || fail "Web build output appears incomplete ($WEB_FILE_COUNT files)."
WEB_ZIP="$HOME/Desktop/FINAL_FX_TV_Manager_WEB_BUILD_${STAMP}.zip"
(cd build && zip -qr "$WEB_ZIP" web)
unzip -t "$WEB_ZIP" | tail -n 2 | tee "$ARTIFACT_DIR/web-build-zip-check.txt"
printf 'Web build archive: %s\nBuilt files: %s\n' "$WEB_ZIP" "$WEB_FILE_COUNT"

printf '\n[7/9] Creating release source archive and saving changes to GitHub...\n'
# If generated Flutter/Firebase caches were historically tracked, untrack them but keep local copies.
git rm -r --cached --ignore-unmatch .firebase build .dart_tool >/dev/null 2>&1 || true
# Add all real source/config/assets, using project .gitignore to keep caches/backups out.
git add -A
git diff --cached --check
printf '\nFiles prepared for the commit:\n'
git diff --cached --stat | tee "$ARTIFACT_DIR/git-staged-stat.txt"
# Extra safety: never stage obvious credential files, even if already present.
if git diff --cached --name-only | grep -E '(^|/)(serviceAccountKey\.json|service-account.*\.json|firebase-adminsdk.*\.json|\.env($|\.)|.*\.(pem|p12|pfx)$)' >/dev/null; then
  git diff --cached --name-only | grep -E '(^|/)(serviceAccountKey\.json|service-account.*\.json|firebase-adminsdk.*\.json|\.env($|\.)|.*\.(pem|p12|pfx)$)' || true
  fail "Credential-looking path is staged. No commit/push/deploy performed."
fi

# Source checksum manifest; omit Git metadata, builds, generated caches, and timestamped backups.
MANIFEST="$ARTIFACT_DIR/source-sha256.txt"
find . \
  -path './.git' -prune -o -path './build' -prune -o -path './.dart_tool' -prune -o \
  -path './.firebase' -prune -o -path './.idea' -prune -o -path './backup' -prune -o -path './lib/backup' -prune -o \
  -type f ! -name '*.backup*' ! -name '*.before_*' ! -name '*.before-*' ! -name '*.log' -print \
  | LC_ALL=C sort | while IFS= read -r f; do shasum -a 256 "$f"; done > "$MANIFEST"
printf 'Source checksum manifest: %s\n' "$MANIFEST"

SOURCE_ZIP="$HOME/Desktop/FINAL_FX_TV_Manager_SOURCE_RELEASE_${STAMP}.zip"
zip -qr "$SOURCE_ZIP" . \
  -x './.git/*' './build/*' './.dart_tool/*' './.firebase/*' './node_modules/*' './.idea/*' \
     './backup/*' './lib/backup/*' './**/backup/*' './*.log' './**/*.backup*' './**/*.before_*' './**/*.before-*' \
     './*.zip' './*.bundle' './.DS_Store' './**/.DS_Store' './**/serviceAccountKey.json' './**/firebase-adminsdk*.json' \
     './**/.env' './**/.env.*' './**/*.pem' './**/*.p12' './**/*.pfx'
unzip -t "$SOURCE_ZIP" | tail -n 2 | tee "$ARTIFACT_DIR/source-zip-check.txt"
printf 'Clean source archive: %s\n' "$SOURCE_ZIP"

if ! git diff --cached --quiet; then
  GIT_NAME="$(git config user.name || true)"
  GIT_EMAIL="$(git config user.email || true)"
  if [[ -z "$GIT_NAME" || "$GIT_NAME" == 'Your Name' || -z "$GIT_EMAIL" || "$GIT_EMAIL" == *example.com ]]; then
    printf '\nGit commit identity is not configured with real values.\n'
    read -r -p 'Name to show on GitHub commit: ' GIT_NAME
    read -r -p 'Email for GitHub commits: ' GIT_EMAIL
    [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]] || fail "Non-empty Git identity is required. Build/archive completed; no push/deploy performed."
    git config --local user.name "$GIT_NAME"
    git config --local user.email "$GIT_EMAIL"
  fi
  git commit -m "Finalize FINAL FX TV Manager release"
else
  printf 'No staged source changes; no new Git commit needed.\n'
fi
git push -u origin "$BRANCH"
printf 'GitHub push complete: origin/%s\n' "$BRANCH"

printf '\n[8/9] Deploying a temporary Firebase Hosting preview...\n'
PREVIEW_LOG="$ARTIFACT_DIR/firebase-preview-deploy.log"
if ! firebase hosting:channel:deploy final-review --only "$HOSTING_TARGET" --project "$PROJECT_ID" --expires 7d > "$PREVIEW_LOG" 2>&1; then
  cat "$PREVIEW_LOG"
  fail "Firebase preview deployment failed. GitHub checkpoint and build archives are saved; production was not deployed."
fi
cat "$PREVIEW_LOG"
PREVIEW_URL="$(sed -nE 's/.*Channel URL \([^)]*\): (https:\/\/[^[:space:]]+).*/\1/p' "$PREVIEW_LOG" | tail -n 1)"
[[ -n "$PREVIEW_URL" ]] || fail "Preview URL could not be parsed. Copy the Channel URL from $PREVIEW_LOG and verify it manually. Production was not deployed."
printf 'Preview URL: %s\n' "$PREVIEW_URL"
PREVIEW_HTML="$ARTIFACT_DIR/preview-index.html"
curl --fail --location --silent --show-error "$PREVIEW_URL" -o "$PREVIEW_HTML" || fail "Preview URL did not return a successful response. Production was not deployed."
grep -qi '<html' "$PREVIEW_HTML" || fail "Preview response did not look like an HTML app. Production was not deployed."
printf 'Preview smoke test: HTTP fetch succeeded and HTML was returned.\n'

printf '\nOpen and manually test the preview before production:\n%s\n' "$PREVIEW_URL"
printf 'Test at least: Dashboard/back navigation; photo upload and list refresh; video upload/preview; single delete; playlists; TV devices; schedule calendar/time/save; template select/use; remote; audit clear confirmation; desktop and mobile widths.\n'
printf '\n[9/9] Production Hosting approval gate\n'
printf 'Only type DEPLOY after the preview works and the critical flows have been tested.\n'
read -r -p 'Type DEPLOY to publish this build to the live site; anything else will skip production: ' APPROVAL
if [[ "$APPROVAL" == 'DEPLOY' ]]; then
  firebase deploy --only "hosting:$HOSTING_TARGET" --project "$PROJECT_ID"
  LIVE_HTML="$ARTIFACT_DIR/live-index.html"
  curl --fail --location --silent --show-error "$LIVE_URL" -o "$LIVE_HTML" || fail "Production deploy command returned, but live URL verification failed. Check Firebase Console immediately."
  grep -qi '<html' "$LIVE_HTML" || fail "Production URL did not return expected HTML. Check Firebase Console."
  printf '\nProduction Hosting deploy and HTTP smoke test completed: %s\n' "$LIVE_URL"
else
  printf '\nProduction deployment SKIPPED. Live site was not modified. Preview is valid for 7 days.\n'
fi

printf '\n================ RELEASE SUMMARY ================\n'
printf 'Project: %s\nBranch: %s\nRemote: %s\n' "$DEST" "$BRANCH" "$REMOTE_URL"
printf 'Source backup: %s\nGit bundle: %s\nSource release ZIP: %s\nWeb build ZIP: %s\nLog directory: %s\n' \
  "$SOURCE_BACKUP" "$GIT_BUNDLE" "$SOURCE_ZIP" "$WEB_ZIP" "$ARTIFACT_DIR"
printf 'Preview URL: %s\nLive URL: %s\n' "$PREVIEW_URL" "$LIVE_URL"
printf 'Finished: %s\n' "$(date)"
