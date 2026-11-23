# The Pothole Portolan Studio

This repository is an unmodified copy of [Blygger Studio](https://github.com/blygger/blygger-studio) (release v0.71.0), deployed as the blyg for [Pothole Portolan](https://github.com/patwater/pothole-portolan). It plays the role that the private `wm-blyg` checkout plays for the World Machines blyg: it holds the engine and this deployment's config, and nothing else.

The research, the dossiers and the automation live in `patwater/pothole-portolan`. Its `blyg-drafts` workflow puts each queued dossier into this Studio as a private draft through the owner API. Nothing is published until the supervisor presses Publish in the Studio.

## What differs from upstream

Only three files, so that upgrades merge cleanly:

- `wrangler.jsonc` names the Worker `pothole-portolan-blyg`, the D1 database `pothole-portolan-blyg` and the R2 bucket `pothole-portolan-blyg-media`. There is no `database_id` and no `account_id`, on purpose: `wrangler deploy` creates the database and bucket by these names on the first deploy and finds them by name afterwards.
- `scripts/pothole-deploy.sh` is the deploy command. It applies the D1 migrations and deploys, in the right order for a first install and for an upgrade.
- This file.

## Deploying from the Cloudflare dashboard

1. **Create the Worker from this repository.** In the Cloudflare dashboard, open Workers & Pages, choose Create, then Import a repository, and pick `patwater/pothole-portolan-blyg`. Set:
   - Project name: `pothole-portolan-blyg` (it must match `name` in `wrangler.jsonc`).
   - Production branch: `main`.
   - Build command: leave empty. `npm ci` runs automatically, and the Studio builds itself in its `postinstall` step.
   - Deploy command: `bash scripts/pothole-deploy.sh`.
   - Under Advanced settings, add the build variable `NODE_VERSION` with the value `22`.
2. **Let the first build run.** It creates the database and the bucket, deploys, and applies the migrations. If the build log shows a permission error on D1 or R2, open the Worker's Settings, then Build, and give the build an API token that has D1 Edit and Workers R2 Storage Edit, then retry the build.
3. **Set the two secrets.** In the Worker's Settings, then Variables and Secrets, add two values of type Secret:
   - `COOKIE_SECRET`: 64 random hex characters, for example from a password manager. Nobody needs to remember it.
   - `OWNER_PASSWORD`: the password you will sign in with. Until it is set, nobody can sign in.
4. **Attach the subdomain.** In the Worker's Settings, then Domains & Routes, add a Custom domain such as `potholes.pioneeringspirit.xyz`. Cloudflare creates the DNS record. Publish nothing before this step, because a blyg's address is part of its identity.
5. **Sign in and configure.** Open `https://<your subdomain>/studio` and sign in. In Settings, set the title (for example "Pothole Portolan"), the author, and the canonical site URL (`https://<your subdomain>/`).

## Connecting the Pothole Portolan automation

1. In the Studio, open More, then Client access. Create a REST API token named `pothole-portolan blyg-drafts` with only `owner:read` and `owner:draft`, and copy it before closing the dialog. It expires after 30 days.
2. In `patwater/pothole-portolan` on GitHub, open Settings, then Secrets and variables, then Actions:
   - Add the secret `BLYGGER_DRAFT_TOKEN` with that token.
   - Add the variable `BLYGGER_API_BASE` with the value `https://<your subdomain>/api`.
   - If that repository is public, add the variable `BLYGGER_ARCHIVE_BASE` with the value `https://github.com/patwater/pothole-portolan/blob/main/`, so archive paths in the dossiers become links.
3. In the Actions tab there, run `blyg-drafts` by hand with the dry run on, then with it off. The San Francisco dossier should appear in the Studio as a draft.

## Upgrading

1. On this repository's GitHub page there is no "Sync fork" button, because it is not a fork. Instead, ask a Claude Code session with this repository attached to merge the latest release tag from `https://github.com/blygger/blygger-studio` into `main` and push. Or, on your own machine with this repository cloned: `git remote add upstream https://github.com/blygger/blygger-studio.git` once, then `npm run upgrade`, then `git push`.
2. The push to `main` triggers the Cloudflare build, which applies any new migrations and deploys.

Read the release notes in `CHANGELOG.md` first. A release whose notes mention a new API contract major version should be checked against `scripts/blygger_client/` in `patwater/pothole-portolan` before the Pothole Portolan workflow runs against it.

## Every month

The Studio token expires after 30 days. Every Studio credential does, by the Studio's design, and no setting changes it. You do not need to track the date: from 7 days before expiry, the `blyg-drafts` workflow in `patwater/pothole-portolan-worker` opens an issue labelled `studio-token` with the renewal steps. Create a new token in the Studio, replace the `BLYGGER_DRAFT_TOKEN` secret, revoke the old token, and close the issue.
