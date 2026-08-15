import fs from 'node:fs/promises';
import path from 'node:path';

function parseEnv(text) {
  const env = {};
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const index = trimmed.indexOf('=');
    if (index === -1) continue;
    env[trimmed.slice(0, index)] = trimmed.slice(index + 1);
  }
  return env;
}

const payloadPath = process.argv[2];
if (!payloadPath) {
  throw new Error('Usage: node tool/import_omolaat_payload.mjs payload.json');
}

const cwd = process.cwd();
const envText = await fs.readFile(path.join(cwd, '.env'), 'utf8').catch(() => '');
const env = { ...parseEnv(envText), ...process.env };

const supabaseUrl = env.SUPABASE_URL;
const anonKey = env.SUPABASE_ANON_KEY;
const importToken = env.OMOLAAT_IMPORT_TOKEN;

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL in .env');
if (!anonKey) throw new Error('Missing SUPABASE_ANON_KEY in .env');
if (!importToken) throw new Error('Missing OMOLAAT_IMPORT_TOKEN in .env');

const payload = JSON.parse(await fs.readFile(payloadPath, 'utf8'));
const endpoint = `${supabaseUrl}/functions/v1/omolaat-coupons-import`;

const response = await fetch(endpoint, {
  method: 'POST',
  headers: {
    apikey: anonKey,
    Authorization: `Bearer ${anonKey}`,
    'Content-Type': 'application/json',
    'x-omolaat-import-token': importToken,
  },
  body: JSON.stringify(payload),
});

const resultText = await response.text();
let result;
try {
  result = JSON.parse(resultText);
} catch {
  result = resultText;
}

if (!response.ok) {
  console.error(result);
  process.exit(1);
}

console.log(JSON.stringify(result, null, 2));
