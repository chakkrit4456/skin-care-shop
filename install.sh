#!/usr/bin/env bash
# Install the shop on the server itself: PostgreSQL, Node.js, nginx, and the API.
# No Docker. Run from the repo root: sudo ./install.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/opt/price-app"
WEB_ROOT="/var/www/price-app"
UPLOAD_DIR="/var/lib/price-app/uploads"
ENV_FILE="/etc/price-app.env"
STATE_FILE="/etc/price-app.install"
API_PORT="3000"

if [[ "${EUID}" -ne 0 ]]; then
  exec sudo bash "$ROOT/install.sh" "$@"
fi

if [[ ! -t 0 ]]; then
  echo "สคริปต์นี้ต้องรันในเทอร์มินัล เพื่อถามเรื่องรหัสแอดมิน"
  exit 1
fi

if [[ ! -f "$ROOT/price_app/pubspec.yaml" || ! -f "$ROOT/server/api/package.json" || ! -f "$ROOT/server/db/001_init.sql" ]]; then
  echo "ไม่พบโปรเจกต์ครบถ้วน ให้รัน install.sh จากโฟลเดอร์รากของ repo"
  exit 1
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
fi
if [[ "${ID:-}" != "debian" ]]; then
  echo "เครื่องนี้ไม่ใช่ Debian (${ID:-unknown}) สคริปต์จัดไว้สำหรับ Debian 13 และจะทำต่อ"
elif [[ "${VERSION_ID:-}" != "13" ]]; then
  echo "พบ Debian ${VERSION_ID:-?} สคริปต์จัดไว้สำหรับ Debian 13 และจะทำต่อ"
else
  echo "Debian 13"
fi

free_kb="$(df -Pk /opt | awk 'NR==2 {print $4}')"
if [[ "${free_kb:-0}" -lt 6000000 ]]; then
  echo "พื้นที่ว่างน้อยกว่า 6GB การ build หน้าเว็บอาจล้มเหลว"
fi

echo "กำลังติดตั้ง PostgreSQL, nginx และเครื่องมือ build..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl openssl git unzip xz-utils zip jq rsync nginx postgresql

systemctl enable --now postgresql
systemctl enable --now nginx

install_node() {
  if command -v node >/dev/null 2>&1; then
    local major
    major="$(node -p 'process.versions.node.split(".")[0]')"
    [[ "$major" -ge 24 ]] && return 0
  fi
  echo "กำลังติดตั้ง Node.js 24..."
  if curl -fsSL https://deb.nodesource.com/setup_24.x | bash -; then
    apt-get install -y nodejs || true
  fi
  if ! command -v node >/dev/null 2>&1 || [[ "$(node -p 'process.versions.node.split(".")[0]')" -lt 24 ]]; then
    local arch ver
    case "$(dpkg --print-architecture)" in
      amd64) arch="x64" ;;
      arm64) arch="arm64" ;;
      *) echo "ไม่รองรับสถาปัตยกรรมสำหรับ Node.js"; exit 1 ;;
    esac
    ver="$(curl -fsSL https://nodejs.org/dist/index.json | jq -r '[.[] | select(.version|startswith("v24."))][0].version')"
    curl -fsSL "https://nodejs.org/dist/${ver}/node-${ver}-linux-${arch}.tar.xz" -o /tmp/node.tar.xz
    tar -C /usr/local --strip-components=1 -xf /tmp/node.tar.xz
    rm -f /tmp/node.tar.xz
    hash -r
  fi
  local got
  got="$(node -p 'process.versions.node.split(".")[0]')"
  if [[ "$got" -lt 24 ]]; then
    echo "ต้องใช้ Node.js 24 ขึ้นไป ได้เวอร์ชัน $(node -v)"
    exit 1
  fi
}

install_flutter() {
  if [[ -x /opt/flutter/bin/flutter ]]; then
    return 0
  fi
  echo "กำลังดาวน์โหลด Flutter SDK..."
  local json base archive arch
  arch="$(dpkg --print-architecture)"
  json="$(curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json)"
  base="$(jq -r '.base_url' <<<"$json")"
  if [[ "$arch" == "arm64" ]]; then
    archive="$(jq -r '[.releases[] | select(.channel=="stable" and (.archive|contains("flutter_linux_arm64_")))][0].archive' <<<"$json")"
  elif [[ "$arch" == "amd64" ]]; then
    archive="$(jq -r '[.releases[] | select(.channel=="stable" and (.archive|contains("flutter_linux_")) and (.archive|contains("arm64")|not))][0].archive' <<<"$json")"
  else
    echo "Flutter รองรับเฉพาะ amd64 และ arm64"
    exit 1
  fi
  if [[ -z "$archive" || "$archive" == "null" ]]; then
    echo "หาไฟล์ Flutter ไม่เจอ"
    exit 1
  fi
  curl -fL "${base}/${archive}" -o /tmp/flutter.tar.xz
  rm -rf /opt/flutter
  tar -C /opt -xf /tmp/flutter.tar.xz
  rm -f /tmp/flutter.tar.xz
}

load_env() {
  local file="$1" line key val
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || continue
    key="${BASH_REMATCH[1]}"
    val="${BASH_REMATCH[2]}"
    if [[ "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"; fi
    if [[ "$val" =~ ^\"(.*)\"$ ]]; then val="${BASH_REMATCH[1]}"; fi
    case "$key" in
      POSTGRES_PASSWORD|JWT_SECRET|ADMIN_USERNAME|ADMIN_PASSWORD|LINE_CHANNEL_ACCESS_TOKEN|LINE_TARGET_ID|LINE_OA_ID|CLOUDFLARE_TUNNEL_TOKEN|WEB_PORT|SKIP_SEED)
        printf -v "$key" '%s' "$val"
        ;;
    esac
  done <"$file"
}

ask_yn() {
  local prompt="$1" default="${2:-n}" reply hint="[y/N]"
  [[ "$default" == "y" ]] && hint="[Y/n]"
  while true; do
    read -r -p "$prompt $hint " reply
    reply="${reply:-$default}"
    case "${reply,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) echo "ตอบ y หรือ n" ;;
    esac
  done
}

assert_oneline() {
  local name="$1" val="$2"
  if [[ "$val" == *$'\n'* || "$val" == *\\* ]]; then
    echo "${name} มีอักขระที่ใช้ในไฟล์ตั้งค่าไม่ได้"
    exit 1
  fi
}

POSTGRES_PASSWORD=""
JWT_SECRET=""
ADMIN_USERNAME="admin"
ADMIN_PASSWORD=""
LINE_CHANNEL_ACCESS_TOKEN=""
LINE_TARGET_ID=""
LINE_OA_ID=""
CLOUDFLARE_TUNNEL_TOKEN=""
WEB_PORT="80"
SKIP_SEED="true"

if [[ -f "$STATE_FILE" ]]; then
  load_env "$STATE_FILE"
elif [[ -f "$ROOT/server/.env" ]]; then
  load_env "$ROOT/server/.env"
fi
[[ -z "$ADMIN_USERNAME" ]] && ADMIN_USERNAME="admin"
[[ -z "$WEB_PORT" ]] && WEB_PORT="80"
[[ -z "$SKIP_SEED" ]] && SKIP_SEED="true"

echo
echo "ตั้งค่าการติดตั้งร้านแต๊ะเอียสกินช็อป"
echo

read -r -p "พอร์ตเว็บ [${WEB_PORT}]: " reply
WEB_PORT="${reply:-$WEB_PORT}"
if [[ ! "$WEB_PORT" =~ ^[0-9]+$ ]] || (( WEB_PORT < 1 || WEB_PORT > 65535 )); then
  echo "พอร์ตไม่ถูกต้อง"
  exit 1
fi

read -r -p "ชื่อผู้ใช้แอดมิน [${ADMIN_USERNAME}]: " reply
ADMIN_USERNAME="${reply:-$ADMIN_USERNAME}"
ADMIN_USERNAME="${ADMIN_USERNAME,,}"
if [[ ! "$ADMIN_USERNAME" =~ ^[a-z0-9_.]{3,30}$ ]]; then
  echo "ชื่อผู้ใช้ต้องยาว 3–30 ตัว และใช้ได้เฉพาะ a-z, ตัวเลข, _ และ ."
  exit 1
fi

generated_pw=false
changed_pw=false
echo
if ask_yn "ต้องการเปลี่ยนรหัสแอดมินหรือไม่?"; then
  changed_pw=true
  while true; do
    read -r -s -p "รหัสแอดมินใหม่ (อย่างน้อย 8 ตัว): " pw1
    echo
    read -r -s -p "ยืนยันรหัสอีกครั้ง: " pw2
    echo
    if [[ "$pw1" != "$pw2" ]]; then
      echo "รหัสไม่ตรงกัน ลองใหม่"
      continue
    fi
    if (( ${#pw1} < 8 || ${#pw1} > 100 )); then
      echo "รหัสต้องยาว 8–100 ตัว"
      continue
    fi
    if [[ "$pw1" == *$'\n'* || "$pw1" == *\\* ]]; then
      echo "รหัสห้ามมีเครื่องหมาย \\ "
      continue
    fi
    ADMIN_PASSWORD="$pw1"
    break
  done
  unset pw1 pw2
else
  if [[ -z "$ADMIN_PASSWORD" || "$ADMIN_PASSWORD" == "change-me-admin" ]]; then
    raw="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9')"
    ADMIN_PASSWORD="${raw:0:16}"
    unset raw
    generated_pw=true
    echo "ยังไม่มีรหัสแอดมินที่ใช้ได้ จึงสร้างรหัสเริ่มต้นให้ แสดงให้ดูตอนจบการติดตั้ง"
  else
    echo "ไม่เปลี่ยนรหัสแอดมิน"
  fi
fi

read -r -p "LINE OA ID เช่น @shop (Enter = คงค่าเดิม, พิมพ์ - เพื่อล้าง) [${LINE_OA_ID}]: " reply
if [[ "$reply" == "-" ]]; then
  LINE_OA_ID=""
elif [[ -n "$reply" ]]; then
  LINE_OA_ID="$reply"
fi
if [[ "$LINE_OA_ID" == *\"* || "$LINE_OA_ID" == *$'\n'* ]]; then
  echo "LINE OA ID ใช้ตัวอักษรนี้ไม่ได้"
  exit 1
fi

use_tunnel=false
token_changed=false
if ask_yn "ใช้ Cloudflare Tunnel หรือไม่?"; then
  if [[ -n "$CLOUDFLARE_TUNNEL_TOKEN" ]]; then
    read -r -s -p "Tunnel token (Enter = ใช้ค่าเดิม): " reply
    echo
    if [[ -n "$reply" ]]; then
      CLOUDFLARE_TUNNEL_TOKEN="$reply"
      token_changed=true
    fi
  else
    read -r -s -p "Tunnel token: " CLOUDFLARE_TUNNEL_TOKEN
    echo
    token_changed=true
  fi
  unset reply
  if [[ -z "$CLOUDFLARE_TUNNEL_TOKEN" ]]; then
    echo "ไม่มี token จึงไม่เปิด tunnel"
  else
    assert_oneline "Tunnel token" "$CLOUDFLARE_TUNNEL_TOKEN"
    use_tunnel=true
    echo "ใน Cloudflare ให้ชี้ public hostname มาที่ HTTP  http://127.0.0.1:${WEB_PORT}"
  fi
fi

if [[ -z "$POSTGRES_PASSWORD" || "$POSTGRES_PASSWORD" == "change-me-strong-password" ]]; then
  POSTGRES_PASSWORD="$(openssl rand -hex 24)"
  echo "สร้างรหัสฐานข้อมูลใหม่แล้ว"
fi
if [[ ${#JWT_SECRET} -lt 32 || "$JWT_SECRET" == "change-me-change-me-change-me-change-me" ]]; then
  JWT_SECRET="$(openssl rand -hex 32)"
  echo "สร้าง JWT_SECRET ใหม่แล้ว"
fi
assert_oneline "รหัสฐานข้อมูล" "$POSTGRES_PASSWORD"
assert_oneline "JWT_SECRET" "$JWT_SECRET"
assert_oneline "รหัสแอดมิน" "$ADMIN_PASSWORD"
assert_oneline "LINE token" "$LINE_CHANNEL_ACCESS_TOKEN"
assert_oneline "LINE target" "$LINE_TARGET_ID"

echo "กำลังเตรียมฐานข้อมูล..."
for _ in $(seq 1 30); do
  if sudo -u postgres pg_isready -q; then
    break
  fi
  sleep 1
done
if ! sudo -u postgres pg_isready -q; then
  echo "PostgreSQL ยังไม่พร้อม"
  exit 1
fi

role_exists="$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='price'")"
if [[ "$role_exists" == "1" ]]; then
  sudo -u postgres psql -v ON_ERROR_STOP=1 -c "ALTER USER price WITH PASSWORD '${POSTGRES_PASSWORD}'"
else
  sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE USER price WITH PASSWORD '${POSTGRES_PASSWORD}'"
fi
db_exists="$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='price'")"
if [[ "$db_exists" != "1" ]]; then
  sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE price OWNER price"
fi
if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h 127.0.0.1 -U price -d price -c "SELECT 1" >/dev/null; then
  echo "ต่อฐานข้อมูล price ไม่สำเร็จ ตรวจว่า pg_hba.conf อนุญาต 127.0.0.1 ด้วย scram-sha-256"
  exit 1
fi

install_node
install_flutter
export PATH="/opt/flutter/bin:${PATH}"
export PUB_CACHE="/var/cache/flutter-pub"
export CI=true
mkdir -p "$PUB_CACHE"

echo
echo "กำลัง build หน้าเว็บ (ครั้งแรกใช้เวลานาน)..."
(
  cd "$ROOT/price_app"
  flutter pub get
  flutter build web --release --dart-define=API_URL=/api --dart-define="LINE_OA_ID=${LINE_OA_ID}"
)

if ! id priceapp >/dev/null 2>&1; then
  useradd --system --no-create-home --shell /usr/sbin/nologin priceapp
fi
install -d -o priceapp -g priceapp -m 755 "$APP_DIR" "$UPLOAD_DIR"
install -d -o www-data -g www-data -m 755 "$WEB_ROOT"

echo "กำลังวางไฟล์แอป..."
rsync -a --delete --exclude node_modules "$ROOT/server/api/" "$APP_DIR/api/"
rsync -a --delete "$ROOT/server/db/" "$APP_DIR/db/"
rsync -a --delete "$ROOT/price_app/build/web/" "$WEB_ROOT/"
chown -R www-data:www-data "$WEB_ROOT"
(
  cd "$APP_DIR/api"
  npm ci --omit=dev --no-audit --no-fund
)
chown -R priceapp:priceapp "$APP_DIR" "$UPLOAD_DIR"

sync_flag=false
[[ "$changed_pw" == true ]] && sync_flag=true

write_env() {
  local sync="$1" old_umask
  old_umask="$(umask)"
  umask 077
  {
    printf 'DATABASE_URL=postgres://price:%s@127.0.0.1:5432/price\n' "$POSTGRES_PASSWORD"
    printf 'JWT_SECRET=%s\n' "$JWT_SECRET"
    printf 'ADMIN_USERNAME=%s\n' "$ADMIN_USERNAME"
    printf 'ADMIN_PASSWORD=%s\n' "$ADMIN_PASSWORD"
    printf 'ADMIN_SYNC_PASSWORD=%s\n' "$sync"
    printf 'LINE_CHANNEL_ACCESS_TOKEN=%s\n' "$LINE_CHANNEL_ACCESS_TOKEN"
    printf 'LINE_TARGET_ID=%s\n' "$LINE_TARGET_ID"
    printf 'SKIP_SEED=%s\n' "$SKIP_SEED"
    printf 'UPLOAD_DIR=%s\n' "$UPLOAD_DIR"
    printf 'DB_DIR=%s\n' "$APP_DIR/db"
    printf 'PORT=%s\n' "$API_PORT"
    printf 'HOST=127.0.0.1\n'
    printf 'NODE_ENV=production\n'
  } >"$ENV_FILE"
  chmod 600 "$ENV_FILE"
  umask "$old_umask"
}

write_state() {
  local old_umask
  old_umask="$(umask)"
  umask 077
  {
    printf 'POSTGRES_PASSWORD=%s\n' "$POSTGRES_PASSWORD"
    printf 'JWT_SECRET=%s\n' "$JWT_SECRET"
    printf 'ADMIN_USERNAME=%s\n' "$ADMIN_USERNAME"
    printf 'ADMIN_PASSWORD=%s\n' "$ADMIN_PASSWORD"
    printf 'LINE_CHANNEL_ACCESS_TOKEN=%s\n' "$LINE_CHANNEL_ACCESS_TOKEN"
    printf 'LINE_TARGET_ID=%s\n' "$LINE_TARGET_ID"
    printf 'LINE_OA_ID=%s\n' "$LINE_OA_ID"
    printf 'CLOUDFLARE_TUNNEL_TOKEN=%s\n' "$CLOUDFLARE_TUNNEL_TOKEN"
    printf 'WEB_PORT=%s\n' "$WEB_PORT"
    printf 'SKIP_SEED=%s\n' "$SKIP_SEED"
  } >"$STATE_FILE"
  chmod 600 "$STATE_FILE"
  umask "$old_umask"
}

write_env "$sync_flag"
write_state

node_bin="$(command -v node)"
cat > /etc/systemd/system/price-api.service <<EOF
[Unit]
Description=Price shop API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=priceapp
Group=priceapp
WorkingDirectory=${APP_DIR}/api
EnvironmentFile=${ENV_FILE}
ExecStart=${node_bin} src/index.ts
Restart=on-failure
RestartSec=3
Umask=0022

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable price-api
systemctl restart price-api

sed -e "s|@@WEB_PORT@@|${WEB_PORT}|g" \
    -e "s|@@WEB_ROOT@@|${WEB_ROOT}|g" \
    -e "s|@@UPLOAD_DIR@@|${UPLOAD_DIR}|g" \
    "$ROOT/server/nginx.conf" > /etc/nginx/sites-available/price-app
ln -sfn /etc/nginx/sites-available/price-app /etc/nginx/sites-enabled/price-app
if [[ "$WEB_PORT" == "80" ]]; then
  rm -f /etc/nginx/sites-enabled/default
fi
nginx -t
systemctl reload nginx

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
  if ask_yn "เปิดพอร์ต ${WEB_PORT}/tcp ใน ufw หรือไม่?" y; then
    ufw allow "${WEB_PORT}/tcp"
  fi
fi

echo "รอให้ API พร้อม..."
ready=false
for _ in $(seq 1 40); do
  if curl -fsS "http://127.0.0.1:${API_PORT}/health" >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done
if [[ "$ready" != true ]]; then
  echo "API ยังไม่ตอบ ดูสาเหตุด้วยคำสั่ง:"
  echo "  journalctl -u price-api -n 80 --no-pager"
  exit 1
fi

if [[ "$changed_pw" == true ]]; then
  write_env false
  systemctl restart price-api
  ready=false
  for _ in $(seq 1 40); do
    if curl -fsS "http://127.0.0.1:${API_PORT}/health" >/dev/null 2>&1; then
      ready=true
      break
    fi
    sleep 2
  done
  if [[ "$ready" != true ]]; then
    echo "ตั้งรหัสแล้ว แต่ API ยังไม่กลับมา"
    echo "  journalctl -u price-api -n 80 --no-pager"
    exit 1
  fi
fi

if ! curl -fsS "http://127.0.0.1:${WEB_PORT}/api/health" >/dev/null 2>&1; then
  echo "nginx ยังไม่ส่งต่อถึง API ที่พอร์ต ${WEB_PORT}"
  exit 1
fi

if [[ "$use_tunnel" == true ]]; then
  if ! command -v cloudflared >/dev/null 2>&1; then
    echo "กำลังติดตั้ง cloudflared..."
    case "$(dpkg --print-architecture)" in
      amd64) cf_arch="amd64" ;;
      arm64) cf_arch="arm64" ;;
      *) echo "cloudflared ไม่รองรับสถาปัตยกรรมนี้"; exit 1 ;;
    esac
    curl -fsSL -o /tmp/cloudflared.deb "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${cf_arch}.deb"
    dpkg -i /tmp/cloudflared.deb || apt-get install -f -y
    rm -f /tmp/cloudflared.deb
  fi
  if [[ "$token_changed" == true ]] || ! systemctl is-active --quiet cloudflared; then
    cloudflared service uninstall >/dev/null 2>&1 || true
    cloudflared service install "$CLOUDFLARE_TUNNEL_TOKEN"
  fi
else
  systemctl disable --now cloudflared >/dev/null 2>&1 || true
fi

ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
echo
echo "ติดตั้งเสร็จแล้ว โดยไม่ได้ใช้ Docker"
if [[ "$WEB_PORT" == "80" ]]; then
  echo "เปิดเว็บที่ http://${ip:-เซิร์ฟเวอร์}/"
else
  echo "เปิดเว็บที่ http://${ip:-เซิร์ฟเวอร์}:${WEB_PORT}/"
fi
if [[ "$generated_pw" == true ]]; then
  echo "รหัสแอดมินที่สร้างให้ (แสดงครั้งนี้ครั้งเดียว):"
  echo "  ผู้ใช้: ${ADMIN_USERNAME}"
  echo "  รหัส:   ${ADMIN_PASSWORD}"
elif [[ "$changed_pw" == true ]]; then
  echo "เปลี่ยนรหัสแอดมินแล้ว ผู้ใช้: ${ADMIN_USERNAME}"
else
  echo "ไม่ได้เปลี่ยนรหัสแอดมิน ผู้ใช้: ${ADMIN_USERNAME}"
fi
if [[ "$use_tunnel" == true ]]; then
  echo "Tunnel ทำงานอยู่ ตั้ง public hostname ใน Cloudflare ให้ชี้มาที่ http://127.0.0.1:${WEB_PORT}"
fi
echo "อัปเดตทีหลัง: git pull แล้วรัน sudo ./install.sh อีกครั้ง"
echo "ค่าลับของ API อยู่ที่ ${ENV_FILE}"
echo "ดูล็อก API: journalctl -u price-api -f"
