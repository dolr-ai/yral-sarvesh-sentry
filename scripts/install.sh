#!/usr/bin/env bash
set -euo pipefail

: "${GOOGLE_CLIENT_ID:?GOOGLE_CLIENT_ID is required}"
: "${GOOGLE_CLIENT_SECRET:?GOOGLE_CLIENT_SECRET is required}"

SENTRY_VERSION="${SENTRY_VERSION:-26.6.0}"
SENTRY_DIR="${SENTRY_DIR:-/home/yral-deploy/sentry-self-hosted}"
SENTRY_URL="${SENTRY_URL:-https://sentry.sarvesh.yral.com}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose v2 is required" >&2
  exit 1
fi

if [[ ! -d "${SENTRY_DIR}/.git" ]]; then
  git clone --depth 1 --branch "${SENTRY_VERSION}" \
    https://github.com/getsentry/self-hosted.git "${SENTRY_DIR}"
else
  git -C "${SENTRY_DIR}" fetch --depth 1 origin tag "${SENTRY_VERSION}"
  git -C "${SENTRY_DIR}" checkout "${SENTRY_VERSION}"
fi

cd "${SENTRY_DIR}"

./install.sh --skip-user-creation --no-report-self-hosted-issues

cat > .env.custom <<EOF
SENTRY_EVENT_RETENTION_DAYS=${RETENTION_DAYS}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
EOF

python3 - <<'PY'
import os
from pathlib import Path

config = Path("sentry/config.yml")
text = config.read_text()
lines = []
for line in text.splitlines():
    if line.startswith("system.url-prefix:") or line.startswith("# system.url-prefix:"):
        continue
    if line.startswith("auth-google.client-id:") or line.startswith("# auth-google.client-id:"):
        continue
    if line.startswith("auth-google.client-secret:") or line.startswith("# auth-google.client-secret:"):
        continue
    lines.append(line)

lines.extend([
    "",
    "system.url-prefix: 'https://sentry.sarvesh.yral.com'",
    f"auth-google.client-id: '{os.environ['GOOGLE_CLIENT_ID']}'",
    f"auth-google.client-secret: '{os.environ['GOOGLE_CLIENT_SECRET']}'",
])
config.write_text("\n".join(lines) + "\n")

conf = Path("sentry/sentry.conf.py")
text = conf.read_text()
marker = "# --- yral-sarvesh-sentry minimal overrides ---"
if marker in text:
    text = text.split(marker)[0].rstrip() + "\n"

text += f"""

{marker}
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
CSRF_TRUSTED_ORIGINS = ["https://sentry.sarvesh.yral.com"]
GOOGLE_DOMAIN_WHITELIST = ["gobazzinga.io"]
SENTRY_OPTIONS["auth.allow-registration"] = False
"""
conf.write_text(text)
PY

docker compose --env-file .env --env-file .env.custom up -d --wait

docker compose --env-file .env --env-file .env.custom run --rm web shell -c '
from sentry.models.authprovider import AuthProvider
from sentry.models.organization import Organization

org = Organization.objects.get(slug="sentry")
AuthProvider.objects.update_or_create(
    organization_id=org.id,
    provider="google",
    defaults={
        "config": {"domains": ["gobazzinga.io"]},
        "default_role": 50,
        "default_global_access": True,
    },
)
'

docker compose --env-file .env --env-file .env.custom restart web taskworker taskscheduler

curl --fail --retry 12 --retry-delay 10 http://127.0.0.1:9000/_health/
