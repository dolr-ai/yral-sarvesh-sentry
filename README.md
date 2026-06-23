# yral-sarvesh-sentry

Minimal self-hosted Sentry installer for Sarvesh-owned services.

This repo intentionally does not vendor or rewrite Sentry. It follows the
official self-hosted flow:

1. Clone `getsentry/self-hosted`.
2. Check out a pinned release.
3. Run upstream `./install.sh`.
4. Apply only the small local config needed for `sentry.sarvesh.yral.com`.
5. Start Sentry with Docker Compose.

## Why Keep A Repo?

A repo is not required to run self-hosted Sentry manually. It is useful here only
because we want a repeatable GitHub Actions workflow and one small install
wrapper.

## Runtime

- Sentry host: `sarvesh-3`
- Public URL: `https://sentry.sarvesh.yral.com`
- Upstream version: `26.6.0`
- Event retention: `30` days
- Google OAuth domain: `gobazzinga.io`

## Required Secrets

GitHub Actions secrets in this repo:

- `SARVESH_1_HOST_IP`
- `SARVESH_2_HOST_IP`
- `SARVESH_3_HOST_IP`
- `MACHINE_ACCESS_PRIVATE_KEY`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`

The Google OAuth client should be created in project `yral-mobile` with:

- Authorized origin: `https://sentry.sarvesh.yral.com`
- Authorized redirect URI: `https://sentry.sarvesh.yral.com/auth/sso/`

## Deploy

Run the `Install or upgrade Sentry` workflow.

After install, create the `yral-billing` project in Sentry and put its DSN in
the `dolr-ai/yral-billing` secret:

`YRAL_BILLING_SENTRY_DSN`
