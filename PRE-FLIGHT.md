# Sentry host preflight

Run this before the first installation on `sarvesh-3`. Installation must stop
unless every gate passes:

| Gate | Required |
| --- | ---: |
| Available RAM | at least 20 GiB |
| Free disk on `/` | at least 120 GiB |
| One-minute load average | below 2.0 |
| CPU | at least 4 cores |
| Docker Compose | 2.32.2 or newer |

Record the dated command output from `free -h`, `df -h /`, `nproc`, `uptime`,
`docker version`, and `docker compose version` in the deployment run summary.
