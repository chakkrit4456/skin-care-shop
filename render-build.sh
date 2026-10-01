#!/usr/bin/env bash
# Render build: Flutter web + API dependencies. Used by render.yaml.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/.cache/flutter-sdk/flutter}"

if [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
  echo "==> Downloading Flutter SDK (stable)"
  base="https://storage.googleapis.com/flutter_infra_release/releases"
  archive="$(curl -fsSL "$base/releases_linux.json" | node -e '
    let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
      const j=JSON.parse(s);const h=j.current_release.stable;
      process.stdout.write(j.releases.find(r=>r.hash===h).archive);});')"
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  curl -fL --retry 3 "$base/$archive" | tar -xJ -C "$(dirname "$FLUTTER_HOME")" --no-same-owner
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_HOME" || true
flutter config --no-analytics >/dev/null
flutter --version

echo "==> Building Flutter web"
cd "$ROOT/price_app"
flutter pub get
flutter build web --release \
  --dart-define=API_URL=/api \
  --dart-define="LINE_OA_ID=${LINE_OA_ID:-}"

echo "==> Installing API dependencies"
cd "$ROOT/server/api"
npm install --omit=dev --no-audit --no-fund
echo "==> Build finished"
