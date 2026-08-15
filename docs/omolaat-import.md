# Omolaat Import

## 1. Supabase Secret

Set one private token for the Edge Function:

```bash
supabase secrets set OMOLAAT_IMPORT_TOKEN="choose-a-long-random-secret"
```

Add the same value to local `.env`:

```env
OMOLAAT_IMPORT_TOKEN=choose-a-long-random-secret
```

## 2. Deploy Function

```bash
supabase functions deploy omolaat-coupons-import
```

## 3. Extract Current Omolaat Store

Open an Omolaat store page in Chrome, then open DevTools Console and paste:

```js
// Paste the contents of tool/omolaat-page-extractor.js
```

The payload is copied to the clipboard. Save it as a JSON file, for example:

```text
/tmp/omolaat-osma.json
```

## 4. Import Payload

```bash
node tool/import_omolaat_payload.mjs /tmp/omolaat-osma.json
```

New Omolaat coupons are inserted with:

```text
approval_status = waiting_approval
import_source = omolaat
```

## Automatic Import

First run opens Chrome with a dedicated saved Omolaat profile. Log in once:

```bash
cd /Users/max/StudioProjects/wffrhasah
/Users/max/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node tool/omolaat-auto-import.mjs --login --headed
```

After logging in, close the Chrome window and test one automatic run:

```bash
/Users/max/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node tool/omolaat-auto-import.mjs --headed
```

To run hourly with macOS launchd:

```bash
mkdir -p /Users/max/StudioProjects/wffrhasah/.omolaat-runs
cp /Users/max/StudioProjects/wffrhasah/tool/com.openai.codex.omolaat-import.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.openai.codex.omolaat-import.plist
```

Logs:

```text
/Users/max/StudioProjects/wffrhasah/.omolaat-runs/launchd.out.log
/Users/max/StudioProjects/wffrhasah/.omolaat-runs/launchd.err.log
```

## n8n Local/VPS Workflow

Run n8n:

```bash
cd /Users/max/StudioProjects/wffrhasah
docker compose -f docker-compose.n8n.yml up -d --build
```

Open:

```text
http://localhost:5678
```

Import this workflow:

```text
/Users/max/StudioProjects/wffrhasah/n8n/wafrah-sah-omolaat-hourly.workflow.json
```

Before activating the workflow, log in to Omolaat once inside the n8n container profile:

```bash
docker compose -f docker-compose.n8n.yml exec n8n node /workspace/tool/omolaat-auto-import.mjs --login --headed
```

On a headless VPS, use this first on a machine with a display, then copy the persistent profile directory into the server's n8n volume. After the session is saved, test:

```bash
docker compose -f docker-compose.n8n.yml exec n8n node /workspace/tool/omolaat-auto-import.mjs
```

Then activate the n8n workflow.
