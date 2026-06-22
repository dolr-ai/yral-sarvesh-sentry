# yral-sarvesh-sentry

Self-hosted Sentry for Sarvesh-owned production services. The stack runs on
`sarvesh-3`, while Caddy on all three `*.sarvesh.yral.com` origins proxies to
Sentry over the private `sentry-web` Swarm overlay.

## Configuration

- Public URL: `https://sentry.sarvesh.yral.com`
- Upstream release: `26.6.0`
- Authentication: Google OAuth, restricted to `@gobazzinga.io`
- Registration: disabled after first-time setup
- Event retention: 30 days
- Mail backend: dummy; monitoring uses the UI, GitHub watchdog and Beszel
- Backups: intentionally disabled; see `RUNBOOK.md` for reconstruction

`scripts/install.sh` is idempotent and wraps the upstream
`getsentry/self-hosted` installer. Secrets are supplied from Vault by the
install workflow and are persisted only in the untracked upstream `.env.custom`.

## Initial rollout

1. Run the host preflight and confirm the gates in `PRE-FLIGHT.md`.
2. Create the Google OAuth web client in `yral-mobile` with origin
   `https://sentry.sarvesh.yral.com` and redirect
   `https://sentry.sarvesh.yral.com/auth/sso/`.
3. Populate the Vault paths referenced by `.github/workflows/install.yml`.
4. Dispatch the install workflow.
5. Create `sarvesh@gobazzinga.io` as the local break-glass superuser, enable
   TOTP, complete the setup wizard, and configure Google Apps auth for
   `gobazzinga.io`.
6. Create team `sarvesh-services` and project `yral-billing`, then store its
   DSN in the billing Vault path.
