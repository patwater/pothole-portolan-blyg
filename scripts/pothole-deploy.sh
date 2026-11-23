#!/usr/bin/env bash
# Deploy command for the Cloudflare dashboard's Git build (Workers Builds) of the Pothole Portolan
# Studio. Not part of upstream Blygger Studio; see POTHOLE-PORTOLAN.md.
#
# Order matters for upgrades: schema first, then the code that expects it. On the very first deploy
# the database does not exist yet, so the deploy runs first (wrangler creates the D1 database and
# R2 bucket by the names in wrangler.jsonc) and the migrations follow.
# In a non-interactive build, `wrangler d1 migrations apply` answers its own prompt with yes.
set -euo pipefail

if npx wrangler d1 info DB >/dev/null 2>&1; then
  echo "Database found: applying any new migrations, then deploying."
  npx wrangler d1 migrations apply DB --remote
  npx wrangler deploy
else
  echo "No database yet: first deploy creates it and the media bucket, then the migrations run."
  npx wrangler deploy
  npx wrangler d1 migrations apply DB --remote
fi
